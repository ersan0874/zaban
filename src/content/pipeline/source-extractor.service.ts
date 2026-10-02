import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { execFile } from 'child_process';
import { mkdtemp, readFile, rm, writeFile } from 'fs/promises';
import JSZip from 'jszip';
import mammoth from 'mammoth';
import { tmpdir } from 'os';
import { join } from 'path';
import { promisify } from 'util';
import { PDFDocument } from 'pdf-lib';
import {
  LLM_PROVIDER,
  type LlmProvider,
  type LlmUsage,
} from '../../ai/llm/llm.types';
import { detectSourceKind } from './source-kind';
import { EXTRACT_SYSTEM, extractPagesRequest } from './prompts';

const execFileAsync = promisify(execFile);
const SOFFICE_TIMEOUT_MS = 180_000;

const MARKDOWN_SCHEMA = {
  type: 'object',
  properties: { markdown: { type: 'string' } },
  required: ['markdown'],
};

/** Turns an uploaded file (any supported format) into page-marked Markdown. */
@Injectable()
export class SourceExtractorService {
  private readonly logger = new Logger(SourceExtractorService.name);

  constructor(
    @Inject(LLM_PROVIDER) private readonly llm: LlmProvider,
    private readonly config: ConfigService,
  ) {}

  async extract(
    file: { originalName: string; mimeType: string; storagePath: string },
    onUsage: (usage: LlmUsage) => Promise<void>,
  ): Promise<string> {
    const detected = detectSourceKind(file.originalName, file.mimeType);
    if (!detected) throw new Error(`Unsupported file: ${file.originalName}`);
    const data = await readFile(file.storagePath);

    switch (detected.kind) {
      case 'text':
        return data.toString('utf8');
      case 'docx': {
        // mammoth drops Word equations (OMML). Documents that contain them
        // go through LibreOffice → PDF so Gemini transcribes math as LaTeX.
        if (await docxHasEquations(data)) {
          const pdf = await this.docxToPdf(data);
          if (pdf) return this.extractPdf(pdf, onUsage);
        }
        // convertToMarkdown is missing from mammoth's typings but supported.
        const converter = mammoth as unknown as {
          convertToMarkdown(input: {
            buffer: Buffer;
          }): Promise<{ value: string }>;
        };
        const result = await converter.convertToMarkdown({ buffer: data });
        return result.value;
      }
      case 'image':
        return this.transcribe(data, detected.mimeType, 1, 1, onUsage);
      case 'pdf':
        return this.extractPdf(data, onUsage);
    }
  }

  /** Converts a .docx with LibreOffice; null when it is unavailable. */
  private async docxToPdf(data: Buffer): Promise<Buffer | null> {
    const bin = this.config.get<string>('CONTENT_SOFFICE_BIN', 'soffice');
    const dir = await mkdtemp(join(tmpdir(), 'zaban-docx-'));
    try {
      const input = join(dir, 'source.docx');
      await writeFile(input, data);
      await execFileAsync(
        bin,
        ['--headless', '--convert-to', 'pdf', '--outdir', dir, input],
        // A private HOME keeps parallel runs from sharing a locked profile.
        { timeout: SOFFICE_TIMEOUT_MS, env: { ...process.env, HOME: dir } },
      );
      return await readFile(join(dir, 'source.pdf'));
    } catch (err) {
      this.logger.warn(
        `LibreOffice conversion failed (${bin}); Word equations will be dropped: ${String(err)}`,
      );
      return null;
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  }

  private async extractPdf(
    data: Buffer,
    onUsage: (usage: LlmUsage) => Promise<void>,
  ): Promise<string> {
    const source = await PDFDocument.load(data, { ignoreEncryption: true });
    const total = source.getPageCount();
    const perChunk = Math.max(
      1,
      Number(this.config.get('CONTENT_PDF_PAGES_PER_CALL', 8)),
    );
    const parts: string[] = [];
    for (let start = 0; start < total; start += perChunk) {
      const count = Math.min(perChunk, total - start);
      const chunk = await PDFDocument.create();
      const pages = await chunk.copyPages(
        source,
        Array.from({ length: count }, (_, i) => start + i),
      );
      pages.forEach((p) => chunk.addPage(p));
      const bytes = Buffer.from(await chunk.save());
      parts.push(
        await this.transcribe(
          bytes,
          'application/pdf',
          start + 1,
          count,
          onUsage,
        ),
      );
    }
    return parts.join('\n\n');
  }

  private async transcribe(
    data: Buffer,
    mimeType: string,
    firstPage: number,
    pageCount: number,
    onUsage: (usage: LlmUsage) => Promise<void>,
  ): Promise<string> {
    const { data: result, usage } = await this.llm.generateJson<{
      markdown: string;
    }>({
      system: EXTRACT_SYSTEM,
      temperature: 0,
      parts: [
        { file: { mimeType, data } },
        { text: extractPagesRequest(firstPage, pageCount) },
      ],
      schema: MARKDOWN_SCHEMA,
    });
    await onUsage(usage);
    const markdown = result.markdown ?? '';
    // Guarantee at least the first page marker even if the model omitted it.
    return /<!--\s*page/i.test(markdown)
      ? markdown
      : `<!-- page ${firstPage} -->\n\n${markdown}`;
  }
}

/** True when the document body contains Word equation objects (OMML). */
export async function docxHasEquations(data: Buffer): Promise<boolean> {
  try {
    const zip = await JSZip.loadAsync(data);
    const xml = await zip.file('word/document.xml')?.async('string');
    return !!xml && /<m:oMath[\s>]/.test(xml);
  } catch {
    return false;
  }
}

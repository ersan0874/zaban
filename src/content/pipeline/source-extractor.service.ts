import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readFile } from 'fs/promises';
import mammoth from 'mammoth';
import { PDFDocument } from 'pdf-lib';
import {
  LLM_PROVIDER,
  type LlmProvider,
  type LlmUsage,
} from '../../ai/llm/llm.types';
import { detectSourceKind } from './source-kind';
import { EXTRACT_SYSTEM, extractPagesRequest } from './prompts';

const MARKDOWN_SCHEMA = {
  type: 'object',
  properties: { markdown: { type: 'string' } },
  required: ['markdown'],
};

/** Turns an uploaded file (any supported format) into page-marked Markdown. */
@Injectable()
export class SourceExtractorService {
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
        // convertToMarkdown is missing from mammoth's typings but supported.
        // Word equation objects are not converted; export math books to PDF.
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

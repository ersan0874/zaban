import { SourceBlock } from '../entities/content-job.entity';

const PAGE_MARKER = /<!--\s*page\s+(\d+)\s*-->/gi;

/**
 * Splits extracted Markdown into numbered blocks of roughly `maxChars`.
 * The AI references blocks by index, so lessons can be mapped back to the
 * exact source text whatever the language or format of the original file.
 */
export function splitIntoBlocks(
  files: Array<{ name: string; markdown: string }>,
  maxChars = 900,
): SourceBlock[] {
  const blocks: SourceBlock[] = [];

  for (const file of files) {
    let page: number | null = null;
    let buffer: string[] = [];
    let bufferPage: number | null = null;
    let size = 0;

    const flush = () => {
      const text = buffer.join('\n\n').trim();
      if (text) {
        blocks.push({
          index: blocks.length,
          file: file.name,
          page: bufferPage,
          text,
        });
      }
      buffer = [];
      size = 0;
      bufferPage = page;
    };

    // Turn page markers into their own paragraphs so they can be tracked.
    const normalized = file.markdown.replace(
      PAGE_MARKER,
      '\n\n<!-- page $1 -->\n\n',
    );
    const paragraphs = normalized.split(/\n\s*\n/);

    for (const raw of paragraphs) {
      const paragraph = raw.trim();
      if (!paragraph) continue;
      const marker = /^<!--\s*page\s+(\d+)\s*-->$/i.exec(paragraph);
      if (marker) {
        page = Number(marker[1]);
        if (buffer.length === 0) bufferPage = page;
        continue;
      }
      const isHeading = /^#{1,6}\s/.test(paragraph);
      if (
        buffer.length > 0 &&
        (isHeading || size + paragraph.length > maxChars)
      ) {
        flush();
      }
      if (buffer.length === 0) bufferPage = page;
      // Very long paragraphs are cut so no block is unbounded.
      for (let i = 0; i < paragraph.length; i += maxChars * 2) {
        const piece = paragraph.slice(i, i + maxChars * 2);
        buffer.push(piece);
        size += piece.length;
        if (size > maxChars) flush();
      }
    }
    flush();
  }

  return blocks;
}

export function renderBlocks(blocks: SourceBlock[]): string {
  return blocks
    .map(
      (b) =>
        `[[B${b.index}${b.page !== null ? ` | ${b.file} p.${b.page}` : ` | ${b.file}`}]]\n${b.text}`,
    )
    .join('\n\n');
}

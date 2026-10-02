import { extname } from 'path';

export type SourceKind = 'pdf' | 'image' | 'docx' | 'text';

const IMAGE_TYPES: Record<string, string> = {
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.heic': 'image/heic',
  '.heif': 'image/heif',
};

const TEXT_EXTENSIONS = new Set(['.txt', '.md', '.markdown', '.csv']);

/** Detects how a file is processed; `null` = unsupported. */
export function detectSourceKind(
  fileName: string,
  mimeType: string,
): { kind: SourceKind; mimeType: string } | null {
  const ext = extname(fileName).toLowerCase();
  if (ext === '.pdf' || mimeType === 'application/pdf') {
    return { kind: 'pdf', mimeType: 'application/pdf' };
  }
  if (IMAGE_TYPES[ext]) return { kind: 'image', mimeType: IMAGE_TYPES[ext] };
  if (mimeType.startsWith('image/')) return { kind: 'image', mimeType };
  if (
    ext === '.docx' ||
    mimeType ===
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ) {
    return {
      kind: 'docx',
      mimeType:
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
  }
  if (TEXT_EXTENSIONS.has(ext) || mimeType.startsWith('text/')) {
    return { kind: 'text', mimeType: 'text/plain' };
  }
  return null;
}

export const SUPPORTED_EXTENSIONS = [
  '.pdf',
  ...Object.keys(IMAGE_TYPES),
  '.docx',
  ...TEXT_EXTENSIONS,
];

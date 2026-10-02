import JSZip from 'jszip';
import { docxHasEquations } from './source-extractor.service';

async function docx(body: string): Promise<Buffer> {
  const zip = new JSZip();
  zip.file(
    'word/document.xml',
    `<w:document xmlns:w="w" xmlns:m="m"><w:body>${body}</w:body></w:document>`,
  );
  return zip.generateAsync({ type: 'nodebuffer' });
}

describe('docxHasEquations', () => {
  it('detects Word equation objects', async () => {
    const data = await docx(
      '<w:p><m:oMath><m:r><m:t>x</m:t></m:r></m:oMath></w:p>',
    );
    await expect(docxHasEquations(data)).resolves.toBe(true);
  });

  it('ignores documents without equations', async () => {
    const data = await docx('<w:p><w:r><w:t>oMath</w:t></w:r></w:p>');
    await expect(docxHasEquations(data)).resolves.toBe(false);
  });

  it('returns false for files that are not zip archives', async () => {
    await expect(docxHasEquations(Buffer.from('plain text'))).resolves.toBe(
      false,
    );
  });
});

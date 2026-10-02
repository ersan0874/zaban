import { splitIntoBlocks } from './source-blocks';

describe('splitIntoBlocks', () => {
  it('tracks pages, splits on headings and size', () => {
    const markdown = [
      '<!-- page 1 -->',
      '# Chapter 1',
      'Intro paragraph.',
      '<!-- page 2 -->',
      'x'.repeat(120),
      'y'.repeat(120),
      '## Part B',
      'tail',
    ].join('\n\n');
    const blocks = splitIntoBlocks([{ name: 'book.pdf', markdown }], 150);
    expect(blocks.map((b) => b.index)).toEqual(blocks.map((_, i) => i));
    expect(blocks[0]).toMatchObject({ page: 1, file: 'book.pdf' });
    expect(blocks[0].text).toContain('# Chapter 1');
    expect(blocks.find((b) => b.text.startsWith('## Part B'))?.page).toBe(2);
    expect(blocks.every((b) => !b.text.includes('<!--'))).toBe(true);
  });

  it('continues numbering across files', () => {
    const blocks = splitIntoBlocks([
      { name: 'a.txt', markdown: 'one' },
      { name: 'b.txt', markdown: 'two' },
    ]);
    expect(blocks).toEqual([
      { index: 0, file: 'a.txt', page: null, text: 'one' },
      { index: 1, file: 'b.txt', page: null, text: 'two' },
    ]);
  });
});

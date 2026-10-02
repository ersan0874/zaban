import { normalizeOutline } from './outline';

describe('normalizeOutline', () => {
  it('clamps block ranges and drops empty parts', () => {
    const outline = normalizeOutline(
      {
        courseTitle: ' Course ',
        courseDescription: 'd',
        sections: [
          {
            title: 'S1',
            units: [
              {
                title: 'U1',
                lessons: [
                  { title: 'L1', objective: 'o', blockStart: 7, blockEnd: -3 },
                  { title: '', objective: 'x', blockStart: 0, blockEnd: 0 },
                ],
              },
              { title: 'Empty unit', lessons: [] },
            ],
          },
          { title: 'Empty section', units: [] },
        ],
      },
      5,
    );
    expect(outline.courseTitle).toBe('Course');
    expect(outline.sections).toHaveLength(1);
    expect(outline.sections[0].units).toHaveLength(1);
    expect(outline.sections[0].units[0].lessons).toEqual([
      { title: 'L1', objective: 'o', blockStart: 0, blockEnd: 4 },
    ]);
  });
});

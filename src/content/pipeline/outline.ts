import { CourseOutline } from '../entities/content-proposal.entity';

export const OUTLINE_SCHEMA = {
  type: 'object',
  properties: {
    courseTitle: { type: 'string' },
    courseDescription: { type: 'string' },
    sections: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          units: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                title: { type: 'string' },
                lessons: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      title: { type: 'string' },
                      objective: { type: 'string' },
                      blockStart: { type: 'integer' },
                      blockEnd: { type: 'integer' },
                    },
                    required: ['title', 'objective', 'blockStart', 'blockEnd'],
                  },
                },
              },
              required: ['title', 'lessons'],
            },
          },
        },
        required: ['title', 'units'],
      },
    },
  },
  required: ['courseTitle', 'courseDescription', 'sections'],
};

const clamp = (n: number, max: number) =>
  Math.max(0, Math.min(max, Math.trunc(Number(n) || 0)));

/**
 * Cleans an outline from the AI or from an admin edit: trims titles, clamps
 * block ranges to the source and drops empty units/sections.
 */
export function normalizeOutline(
  outline: CourseOutline,
  blockCount: number,
): CourseOutline {
  const last = Math.max(0, blockCount - 1);
  const sections = (outline?.sections ?? [])
    .map((section) => ({
      title: String(section?.title ?? '')
        .trim()
        .slice(0, 255),
      units: (section?.units ?? [])
        .map((unit) => ({
          title: String(unit?.title ?? '')
            .trim()
            .slice(0, 255),
          lessons: (unit?.lessons ?? [])
            .map((lesson) => {
              const start = clamp(lesson?.blockStart, last);
              const end = clamp(lesson?.blockEnd, last);
              return {
                title: String(lesson?.title ?? '')
                  .trim()
                  .slice(0, 255),
                objective: String(lesson?.objective ?? '').trim(),
                blockStart: Math.min(start, end),
                blockEnd: Math.max(start, end),
              };
            })
            .filter((lesson) => lesson.title),
        }))
        .filter((unit) => unit.title && unit.lessons.length > 0),
    }))
    .filter((section) => section.title && section.units.length > 0);

  return {
    courseTitle: String(outline?.courseTitle ?? '')
      .trim()
      .slice(0, 255),
    courseDescription: String(outline?.courseDescription ?? '').trim(),
    sections,
  };
}

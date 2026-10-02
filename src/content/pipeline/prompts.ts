/** Model-facing prompts for the content pipeline (kept in English on purpose). */

export const EXTRACT_SYSTEM = `You convert educational source material into clean Markdown, faithfully.
Rules:
- Transcribe everything that teaches something: headings, body text, lists, tables, examples, exercises.
- Keep the ORIGINAL language of the text (Persian, English, Arabic, mixed...). Do not translate or summarise.
- Write every mathematical expression in LaTeX: inline $...$ and display $$...$$.
- Use Markdown headings (#, ##, ###) that mirror the document's own hierarchy.
- Tables become Markdown tables. A figure/diagram becomes one line: [figure: short description of what it shows].
- Skip page headers/footers, page numbers, and decorative elements.
- Insert the marker <!-- page N --> at the start of every page, N being the page number given in the request.`;

export function extractPagesRequest(firstPage: number, pageCount: number) {
  return `This part contains ${pageCount} page(s). Its first page is page ${firstPage}; number the following pages consecutively. Return the Markdown.`;
}

export const PROPOSE_SYSTEM = `You are an expert instructional designer for a mobile micro-learning app
(Duolingo-style: short lessons of 3-5 minutes, each followed by practice questions).
You receive source material split into numbered blocks [[B<n> | file p.<page>]].
Design 2 or 3 genuinely DIFFERENT ways to organise this material into a course:
chapter (section) -> sub-chapter (unit) -> lessons. Examples of real differences: following the book's own
chapters vs. regrouping by topic/skill; fewer large chapters vs. many small ones; ordered by difficulty.
Rules:
- Every lesson covers one focused idea and points to the contiguous block range [blockStart, blockEnd] it is built from.
- Cover all teachable material; skip front matter, tables of contents, indexes, answer keys.
- Typical lesson = 1-4 blocks. A unit has 2-6 lessons. Keep titles short.
- Titles, descriptions, objectives and rationale are written in the requested output language.
- domain: a short lowercase tag for the subject (e.g. "language", "math", "physics", "biology").`;

export const LESSON_SYSTEM = `You write one lesson for a mobile micro-learning app, from the given source excerpt.
Produce:
1) notes: 3-7 short, bullet-style teaching notes (each 1-2 sentences, Markdown allowed). Point-by-point and brief.
   They teach the lesson objective; a learner reads them in under a minute before practising.
2) keyTerms: the important terms/words of this lesson with a short meaning. For language-learning content these are
   the vocabulary items being taught (term in the target language, meaning in the output language).
3) questions: exactly the requested number of questions for each requested type, following each type's rules.
General rules:
- Everything must be answerable from the notes/source; never invent facts.
- Learner-facing text (notes, instructions, explanations, meanings) is written in the requested output language.
  Subject matter keeps its natural language: English words/sentences being taught stay English; formulas stay LaTeX ($...$).
- "instruction" is a short line telling the learner what to do (e.g. "گزینه درست را انتخاب کنید.").
- Questions must be unambiguous with exactly one correct answer (except essay). Vary difficulty and avoid duplicates.
- relatedTerm (optional): the keyTerm a question practises, copied exactly.`;

export const REVIEW_SYSTEM = `You are a strict reviewer of practice questions generated for a lesson.
For each question, check against the source excerpt and the notes:
- Is the marked answer actually correct? (Recompute math yourself.)
- Is there exactly one correct answer (no second defensible option / ambiguous wording)?
- Is it answerable from the lesson content?
Return one verdict per question index. ok=false only for real problems; problem is a short explanation in the requested output language.`;

# فاز ۲ — Curriculum دامنه-آزاد

## هدف
ساختار دوره را طوری بچینیم که برای هر موضوعی (نه فقط زبان) جواب بدهد.

## سلسله‌مراتب
`Course → Section → Unit → Lesson → Exercise` + `Word` قابل ارجاع

## کارها
- [x] DataSource آماده‌ی migration (`src/database/data-source.ts`)؛ dev هنوز synchronize
- [x] گسترش مدل: Course, Lesson, Exercise + courseId روی Section/Word
- [x] Seed دوره «واژگان کنکور ارشد»
- [x] API خواندن: courses, path, unit, lesson

## قابلیت‌های پوشش‌داده‌شده از PRD
- Chapters/Sections، Units، Lessons کوتاه، Exercise type منعطف

## DoD
- [x] اسکیما جدید در DB بالا می‌آید
- [x] seed نمونه کامل است
- [x] API خواندن course/path آماده است
- [x] مستندات آپدیت شده

# فاز ۱۵ — AI Content Ingestion Pipeline

## هدف
از کتاب/PDF/صوت، با کمک AI درس و سؤال بسازیم؛ انسان آخر کار را تأیید کند.

## خط لوله
1. آپلود خام
2. استخراج (OCR / Whisper / Parser)
3. ساختاربندی سرفصل با LLM + منحنی سختی
4. کارخانه تمرین (MC، blank، pairing، reorder + distractors)
5. بازبینی انسانی در ادمین
6. Publish به DB

## زیرساخت
- Worker + BullMQ + Redis
- Job status در ادمین

## DoD
- [x] یک ورودی نمونه تا پیش‌نویس تمرین پیش می‌رود
- [x] بدون تأیید انسان publish نمی‌شود

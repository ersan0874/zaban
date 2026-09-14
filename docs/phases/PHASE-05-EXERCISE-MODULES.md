# فاز ۵ — موتور تمرین ماژولار (همه انواع)

## هدف
هر نوع سؤال یک ماژول جدا داشته باشد (مثل لگو).

## انواع الزامی
- [x] multiple_choice (تقویت موجود)
- [x] matching / pairing
- [x] cloze / blank
- [x] word_bank tapping
- [x] translation دو طرفه
- [x] reorder / sorting
- [x] listening عادی + آهسته (UI؛ asset کامل در فاز ۱۲)
- [x] speaking + STT (UI/قرارداد؛ موتور کامل در فاز ۱۲)
- [x] image-word (در صورت media)

## برای هر نوع
- [x] renderer در Flutter (`ExerciseModuleRouter`)
- [x] validator در Nest (`exercise-grader.ts`)
- [x] قرارداد jsonb در API-CONTRACT

## DoD
- [x] همه انواع بالا حداقل با قرارداد + UI/validator پایه پوشش دارند
- [x] نوع ناشناخته پیام امن می‌دهد (نه کرش)

# تصمیم‌های معماری (DECISIONS / ADR)

## ADR-001 — مستندات اجرایی اجباری
- تاریخ: 2026-09-12
- تصمیم: هر ایجنت قبل از کد `AGENTS.md` و `docs/` را می‌خواند؛ پایان فاز بدون آپدیت PROGRESS/CHANGELOG ممنوع است.
- دلیل: کنترل فازبندی و جلوگیری از جا افتادن قابلیت.

## ADR-002 — پنل ادمین Next.js
- تاریخ: 2026-09-12
- تصمیم: ادمین در پوشه `admin/` با Next.js روی همان Nest API.
- دلیل: جداسازی بک‌آفیس از موبایل؛ اکوسیستم وب قوی برای CMS/Analytics.

## ADR-003 — Thin client + اعتبارسنجی سرور
- تاریخ: 2026-09-12
- تصمیم: محتوای درس on-demand؛ اقتصاد و صحت جواب فقط سرور.
- دلیل: ضدتقلب و ضد استخراج محتوا از APK.

## ADR-004 — Domain-agnostic curriculum
- تاریخ: 2026-09-12
- تصمیم: سلسله‌مراتب Course→Section→Unit→Lesson→Exercise؛ اولین seed = واژگان کنکور انگلیسی.
- دلیل: قابلیت استفاده برای موضوعات دیگر بدون بازنویسی کلاینت.

## ADR-007 — Lesson sessions و نمره‌دهی سرور
- تاریخ: 2026-09-12
- تصمیم: شروع درس فقط با JWT؛ پاسخ‌ها در `POST /sessions/:id/submit` فقط سمت سرور grade می‌شوند؛ answer در payload نشست نیست.
- Rate limit با Throttler.
- دلیل: thin client + ضدتقلب.

## ADR-008 — ماژول‌های تمرین جدا + grader یکپارچه
- تاریخ: 2026-09-12
- تصمیم: هر `QuestionType` content/answer جدا دارد؛ Flutter با `ExerciseModuleRouter` رندر می‌کند؛ همه انواع در یک `gradeExercise` سرور نمره می‌گیرند.
- listening / speaking / image_word تا فاز ۱۲ stub media دارند ولی قرارداد و نمره از الان فعال است.
- دلیل: افزودن نوع جدید بدون بازنویسی کل آزمون.

## ADR-009 — Progress و SRS سمت سرور
- تاریخ: 2026-09-12
- تصمیم: skill و موعد مرور فقط روی سرور در `item_progress`؛ غلط فوراً due؛ تزریق مرور به نشست درس از بانک تمرین جدا.
- دلیل: thin client + ضدتقلب؛ کلاینت فقط صف و نمره را نشان می‌دهد.

## ADR-010 — اقتصاد انرژی و Combo سمت سرور
- تاریخ: 2026-09-12
- تصمیم: موجودی و regen فقط سرور؛ شروع درس burn می‌کند؛ پاداش combo با رول سرور و لجر `energy_transactions`.
- دلیل: ضدتقلب؛ کلاینت فقط HUD و انیمیشن نشان می‌دهد.

## ADR-011 — Gamification Core سمت سرور
- تاریخ: 2026-09-12
- تصمیم: XP، استریک، قلب، کوئست، نشان و لوت فقط سرور اعطا/محاسبه می‌کند؛ فریز استریک موجودی دارد و خرید جم در فاز ۹.
- دلیل: ضدتقلب و یک منبع حقیقت برای انگیزه روزانه.

## ADR-012 — Admin role و ban
- تاریخ: 2026-09-12
- تصمیم: `User.role` (`user|admin`) در JWT payload؛ `AdminGuard` روی `/api/admin/*`؛ `User.banned` در login چک می‌شود.
- دلیل: جداسازی دسترسی بک‌آفیس بدون auth جدا.

## ADR-013 — AI pipeline با human gate
- تاریخ: 2026-09-12
- تصمیم: `AiJob` با status machine؛ publish فقط از `POST .../approve`؛ MVP in-process async (`setImmediate`)؛ BullMQ در `ai.processor.ts` برای prod.
- دلیل: کیفیت محتوا قبل از انتشار در DB.

## ADR-014 — IAP verify و unlimited subscription
- تاریخ: 2026-09-12
- تصمیم: `Purchase` + `EnergySubscription`؛ verify سمت سرور؛ `TEST.*` برای dev؛ unlimited sub → skip energy burn.
- دلیل: ضدتقلب رسید و monetization بدون دور زدن اقتصاد انرژی.

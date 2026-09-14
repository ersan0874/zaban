# نیازمندی‌های محصول (PRD) — چک‌لیست کامل

هر آیتم باید در یک فاز مشخص پیاده شود. وضعیت: `[ ]` باز / `[x]` انجام‌شده.

## A. اقتصاد انرژی (Energy / Move)

- [x] تولید خودکار هر X دقیقه تا سقف Cap
- [x] مصرف ۱ واحد با ورود درس یا حل سؤال
- [x] Combo: ۵ درست متوالی → انیمیشن + پاداش تصادفی ۱–۷ انرژی (سرور)
- [x] خرید بسته انرژی با پول / جم
- [x] اشتراک انرژی نامحدود (۱روز / ۱هفته / ۱ماه)

## B. بازگشت و نگهداشت

- [x] Dynamic App Icon بعد از چند روز غیبت (stub — پلتفرم محدود؛ بنر diagnostic جایگزین)
- [x] Re-entry Diagnostic Test بعد از غیبت طولانی
- [x] تزریق مرور SRS بر اساس افت حافظه
- [x] Social Streak (دیدن استریک دوستان)
- [x] Push notifications (تنظیم‌پذیر — PATCH settings؛ ارسال push فاز بعد)

## C. کورس، محتوا، لول

- [x] Mastery Score 1–100 در سطح Course
- [x] Chapters / Sections با ساختار در DB
- [x] Units / Milestones روی Path (API path)
- [x] Lessons ۳–۵ دقیقه‌ای (estimatedMinutes در seed)
- [x] Checkpoint Exam هر ۷–۱۰ درس + قفل مسیر
- [x] Loot Boxes هر N درس (الماس / انرژی / بوستر)

## D. گیمیفیکیشن و رقابت

- [x] Daily Quests + Quest Points
- [x] آستانه Club با مزایای انحصاری
- [x] Badges + Pin روی پروفایل
- [x] Competitive Leagues + matchmaking
- [x] Gems + In-App Shop (فریز، بوستر، کاستومایز)
- [x] Streak + Streak Freeze
- [x] Hearts / Health
- [x] XP

## E. اجتماعی و UI

- [x] News / Activity Feed
- [x] Direct / Social Chat
- [x] Profile + Avatar customization (پایه: نام، bio، آواتار URL)
- [x] تنظیمات اعلان
- [ ] آمار تسلط و نشان‌ها

## F. یادگیری و تمرین

- [x] Path خطی قابل کلیک (از API)
- [x] مطالعه واژه (معنی، مترادف، مثال) از API
- [x] multiple_choice (از session؛ نمره سرور)
- [x] matching / pairing (UI + grader)
- [x] cloze / blank (UI + grader)
- [x] word bank tapping
- [x] ترجمه دوطرفه
- [x] reorder / sorting
- [x] listening عادی + آهسته (UI/قرارداد؛ صوت در فاز ۱۲)
- [x] speaking + STT (UI/قرارداد؛ موتور STT در فاز ۱۲)
- [x] تصویر-واژه (UI/قرارداد؛ media در فاز ۱۲)
- [x] SRS / مرور هوشمند

## G. معماری محصول

- [x] Thin client (بدون دیتابیس درس در APK) — مسیر session بدون answer
- [x] On-demand chunking نشست درس
- [x] Server-side validation پاسخ (پایه؛ اقتصاد بعدی)
- [x] Domain-agnostic: Course→Section→Unit→Lesson→Exercise
- [x] Auth JWT + Profile
- [x] تنظیمات اعلان در پروفایل (پایه)
## H. ادمین و AI و زیرساخت

- [x] پنل ادمین کاربران + ban
- [x] Analytics (retention, drop-off, زمان مطالعه, combo)
- [x] CMS محتوا + پیش‌نمایش
- [x] AI Studio: آپلود خام → استخراج → ساختاربندی → کارخانه سؤال → moderation
- [ ] OCR / Whisper / Parser (MVP: text-only؛ stub برای media)
- [x] Worker queue برای پردازش سنگین (in-process MVP؛ BullMQ stub + Redis in compose)
- [x] Docker Compose: api, worker, postgres, redis, nginx, admin
- [x] SSL / reverse proxy (nginx + certbot placeholder in README)
- [x] IAP اعتبارسنجی سمت سرور

## نگاشت سریع به فازها

| بخش PRD | فازها |
|---------|--------|
| G Auth | 1 |
| C/G Curriculum schema | 2 |
| G Thin client session | 3 |
| F Path/Study wire | 4 |
| F Exercise types | 5 (+12 برای audio/speech) |
| F SRS | 6 |
| A Energy | 7 |
| D Core gamification | 8 |
| D Leagues/Shop | 9 |
| C Mastery/Checkpoint | 10 |
| B/E Social + re-entry بخشی | 11, 13 |
| F Media | 12 |
| H Admin | 14 |
| H AI | 15 |
| H DevOps | 16 |
| A Monetization | 17 |

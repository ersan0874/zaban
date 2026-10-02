# Changelog

ثبت تغییرات مهم پروژه. جدیدترین بالا.

## 2026-10-02 — رفع ایرادهای تست فصل ۱

### Fixed
- اپ: متن سؤال چندگزینه‌ای (`content.stem`) نمایش داده می‌شود (BUG-006)
- API: ویرایش جزئی درس/تمرین در پنل مدیریت فیلدهای ارسال‌نشده را پاک نمی‌کند (BUG-007)
- API: آمار پنل مدیریت (`GET /admin/analytics`) دیگر خطای ۵۰۰ نمی‌دهد (BUG-008)
- اپ: جهت جمله‌های انگلیسی در ترجمه، جای خالی و گزینه‌ها درست است (BUG-009)
- اپ: بخش‌های خالی صفحه‌ی مطالعه پنهان می‌شوند (BUG-010)
- اپ: تب‌های باشگاه، دوستان و پروفایل با هر بار باز شدن تازه می‌شوند (BUG-011)

### Why
- این ایرادها در اجرای آزمایشی با فصل ۱ کتاب واژگان (۳۰ درس تولیدشده با Gemini) پیدا شدند.

## 2026-10-02 — انرژی هر صفحه، کومبو پلکانی و بازخورد فوری

### Added
- API: `POST /sessions/:id/steps` (نمره فوری + ۱ انرژی + کومبو)؛ `src/energy/combo.ts`؛ ستون‌های `user_energy.comboStreak`، `lesson_sessions.steps/comboRewards` (migration `EnergyPerPage`)
- اپ: نوار بازخورد درست/غلط با پاسخ صحیح، صفحه‌ی کومبو (سه سطح)، شیت «انرژی تمام شد» با شمارنده و شارژ از فروشگاه، شمارنده انرژی و کومبو در بالای درس، تأیید خروج وسط درس
- ماسکوت «زبی»، کاغذرنگی، کارت استریک و جشن پایان درس
- صدا و لرزش (`FeedbackFx`، فایل‌های `assets/sounds`)، حالت تاریک و کلید صدا در پروفایل
- CI: job `mobile` (analyze + test)

### Changed
- انرژی در شروع درس نمی‌سوزد؛ هر صفحه ۱ انرژی (قبلاً ۱ انرژی برای کل درس). بازه‌ی پاداش از ۱–۷ ثابت به پلکانی (ADR-019)
- کل اپ راست‌به‌چپ؛ `submit` نمره‌ها را از `steps` می‌خواند و تمرین بدون `step` را رد می‌کند
- `ENERGY_LESSON_COST` → `ENERGY_STEP_COST` (قدیمی هنوز خوانده می‌شود)

### Fixed
- `widget_test` خراب (به شبکه/پلاگین وابسته بود) با تست‌های سبک جایگزین شد؛ هشدار `auth_service`

### Removed
- ویجت‌های بلااستفاده `StatsHeaderBar` و `ShopBottomSheet`

### Why
درخواست کاربر: انرژی باید با هر صفحه کم شود و رشته‌ی بی‌اشتباه جایزه‌ی بزرگ‌تر بدهد؛ همراه با پیشنهادهای RTL، بازخورد فوری، جشن، صدا و حالت تاریک.
## 2026-10-02 — فاز ۲۰: تکمیل محتوای AI (بدون تانل)

### Added
- فایل Word دارای معادله → LibreOffice → PDF → Gemini (LaTeX)؛ `CONTENT_SOFFICE_BIN`؛ LibreOffice در Docker image (`WITH_LIBREOFFICE`)
- `GET /api/me/late-grades` و `POST /api/me/late-grades/seen`؛ ستون‌های `lateGradedAt`/`lateGradeUnseen` + migration `LateGrades`
- اپ: برگه «نمره پاسخ‌های تشریحی‌ات رسید» هنگام باز شدن مسیر
- اپ: `NoteContent` — جدول، تیتر، فهرست، تصویر و `[figure: ...]` در نکته‌ها
- تست‌ها: `source-extractor.spec.ts`، `note_content_test.dart`، `rtl_math_order_test.dart`

### Fixed
- ترتیب فرمول‌ها در جمله‌های فارسی (BUG-005)
- تست دود Flutter (BUG-004)
- حذف معادله‌های Word (BUG-002)

### Why
کاربر خواست همه کارهای باقی‌مانده محتوای AI به‌جز تانل تمام شود.

## 2026-10-02 — فاز ۱۹: نمایش محتوای AI در اپ

### Added (Flutter)
- `MathText` — رندر LaTeX (`flutter_math_fork`) و Markdown سبک با جهت خودکار
- صفحه «نکته‌های این درس» قبل از تمرین و دکمه نکته‌ها وسط تمرین
- ماژول‌های `true_false`، `short_answer`، `essay`
- کارت‌های بازخورد در صفحه نتیجه (نمره تشریحی، در صف تصحیح، پاسخ نمونه، توضیح)
- انتخاب درس در یونیت‌های چنددرسی
- `test/ai_content_test.dart` (۷ تست)

### Changed
- `LessonSessionPayload` فیلد `notes` دارد؛ `QuizScreen` پارامتر `notes` می‌گیرد
- متن صورت سؤال و گزینه‌ها با `MathText` نمایش داده می‌شود

### Why
محتوای ساخته‌شده با AI (فاز ۱۸) باید در اپ قابل دیدن و تمرین باشد، از جمله فرمول‌های ریاضی.

## 2026-10-02 — فاز ۱۸: تولید محتوا با AI (Gemini)

### Added
- `src/ai/llm/` — `LlmProvider` + `GeminiProvider` (`@google/genai`): خروجی JSON Schema، rate limit، retry، fallback به مدل lite، سقف روزانه
- `src/content/` — `ContentJob`/`SourceFile`/`Proposal`/`DraftLesson`/`DraftExercise`، صف BullMQ، API `/api/admin/content/*`
- استخراج PDF (تکه‌ای)، عکس، Word (`mammoth`) و متن؛ بلوک‌های منبع شماره‌دار
- `src/questions/registry/` — هر نوع سؤال یک ماژول (تولید، validate، grade)؛ انواع جدید `true_false`، `short_answer`، `essay`
- `Lesson.notes`؛ `SessionAttempt.score/feedback/gradingStatus`؛ نمره تشریحی با Gemini + `ESSAY_AI_DAILY_LIMIT` + نمره‌دهی دوباره در پس‌زمینه
- `src/worker.ts` و سرویس `worker` واقعی در Docker؛ volume آپلود؛ `client_max_body_size` در nginx
- پنل ادمین: صفحه‌های `AI Content` (آپلود، انتخاب ساختار، بازبینی، انتشار، تست اتصال)
- migrationها: `Baseline` و `ContentPipeline`؛ با `DB_SYNC=false` هنگام بالا آمدن اجرا می‌شوند

### Changed
- grader نشست‌ها async شد و از رجیستری می‌خواند؛ خروجی شامل score/feedback
- `package-lock.json` همگام شد (`npm ci` در CI خطا می‌داد)؛ `app.controller.spec` درست شد

### Removed
- stub قبلی `AiJob` و مسیرهای `/api/admin/ai/jobs*` و صفحه `ai-jobs` (جدول `ai_jobs` دست‌نخورده می‌ماند)

### Why
کاربر خواست محتوای آموزشی از روی فایل‌های واقعی با AI ساخته شود، برای هر درسی، با سؤال‌های ماژولار و بازبینی انسانی.

## 2026-10-02 — بازطراحی ظاهر اپ (الهام از دولینگو)

### Changed (Flutter)
- پالت جدید با معنی ثابت: سبز=پیشروی/درست، آبی=انتخاب، زرد=جایزه/XP، نارنجی=استریک، مرجانی=قلب، بنفش=جم/Super؛ زمینه سفید بدون گرادیان
- `AppTheme.chunkyStyle`: دکمه‌های سه‌بعدی (لبه تیره زیر دکمه که با لمس فرو می‌رود) برای همه `ElevatedButton`/`OutlinedButton`
- ویجت `ChunkyTile` برای گزینه‌های تمرین، جفت‌کردن و بانک واژه
- مسیر: گره‌های دایره‌ای سکه‌ای، مسیر پیچ‌وتاب‌دار، حباب «شروع» روی درس فعلی، بنر یونیت سبز، نوار آمار ساده
- آزمون: نوار پیشرفت ضخیم، نتیجه با جام و کاشی‌های آمار
- ناوبری پایین با آیکن‌های رنگی؛ لوگوی سبز در صفحه ورود؛ فونت متن Vazirmatn و اعداد/انگلیسی Nunito
- ویجت‌های مشترک `widgets/zaban_ui.dart` (ZCard، ZBanner، ZStatTile، ZAvatar، ZProgressBar، ZMessage) و بازطراحی باشگاه (پیشرفت/لیگ/فروشگاه)، دوستان و چت، پروفایل، پیشرفت و مرور، مطالعه واژه، آزمون تعیین سطح و Super

### Fixed (CI)
- `package-lock.json` ریشه با `package.json` هم‌گام شد (`npm ci` شکست می‌خورد)
- تست `app.controller.spec.ts` ماک `Question` repository را کم داشت

### Why
کاربر طراحی قبلی را جذاب نمی‌دانست؛ ظاهر شاد و ساده‌تر برای انگیزه یادگیری. منطق و API دست نخورد.

## 2026-09-15 — پاس UI: نمایش قابلیت‌ها در ناوبری

### Changed (Flutter)
- `HomeShell` با ۴ تب: مسیر، باشگاه، دوستان، من
- صفحات اجتماعی (فید/دوستان/چت)، لیگ، فروشگاه جم + IAP در دسترس از ناوبری
- هدر آماری مسیر (انرژی/قلب/استریک/XP/جم)؛ لینک Super از پروفایل
- `AuthGate` → placement در صورت نیاز، سپس `HomeShell`
- Repositoryهای `economy` / `social` / `mastery`

### Why
قابلیت‌های فازهای ۵–۱۷ ساخته شده بودند ولی در اپ تقریباً دیده نمی‌شدند.

## 2026-09-12 — فازهای ۱۴–۱۷ تمام شد

### Added (Phase 14 — Admin)
- `User.role` (`user|admin`) + `User.banned`; seed `admin@zaban.local` / `Admin1234!`
- `src/admin/` — AdminGuard, users/analytics/CMS endpoints
- `admin/` Next.js App Router: login, users, analytics, CMS, AI jobs, purchases
- Banned users blocked at login

### Added (Phase 15 — AI)
- `AiJob` entity + pipeline (extract → structure → generate → awaiting_review)
- `POST /admin/ai/jobs/:id/approve` — human gate before publish
- `src/ai/ai.processor.ts` BullMQ stub

### Added (Phase 16 — DevOps)
- Root `Dockerfile`, `admin/Dockerfile`, `docker-compose.yml`
- `nginx/nginx.conf` reverse proxy `/api` + `/admin`
- `GET /api/health`, `scripts/backup-db.sh`, `.github/workflows/ci.yml`

### Added (Phase 17 — Monetization)
- `Purchase`, `EnergySubscription` entities
- `POST /billing/verify`, `GET /billing/me`, `GET /admin/purchases`
- Unlimited subscription skips `EnergyService.burnForLessonStart`
- Flutter `ShopScreen` with TEST receipt purchases

### Why
Admin ops, AI content workflow, deployability, and real-money IAP foundation.

## 2026-09-12 — فاز ۱۳ تمام شد (Re-engagement)

### Added (Backend)
- `UserReentry` entity؛ غیبت >۳ روز → `requiresDiagnostic`
- `GET /api/reengagement/status`, `POST /api/reengagement/diagnostic/complete`
- Gate نشست: `DIAGNOSTIC_REQUIRED` اگر diagnostic لازم و درس غیر-diagnostic
- Seed/patch: درس `آزمون بازگشت` با `lessonKind=diagnostic`

### Added (Flutter)
- بنر آزمون بازگشت روی مسیر؛ `ReengagementRepository`
- Stub `DynamicAppIcon` (پلتفرم‌های محدود)

### Why
بازگشت کاربر بعد از غیبت بدون از دست دادن سطح.

## 2026-09-12 — فاز ۱۲ تمام شد (Media & Audio)

### Added (Backend)
- `public/audio/*.wav` + `npm run generate:audio`
- Nest `useStaticAssets` → `/audio/abandon.wav`
- Seed listening: `audioUrl`, `slowAudioUrl`

### Added (Flutter)
- `ListeningModule` با پخش normal/slow
- Speaking: یادداشت STT + نمره سرور
- انیمیشن burst بین سؤالات و نتیجه pass/retry

### Why
شنیدن واقعی و UX speaking کنترل‌شده.

## 2026-09-12 — فاز ۱۱ تمام شد (Social)

### Added (Backend)
- `Friendship`, `FeedItem`, `ChatMessage`
- `POST /api/social/friends/request`, `POST .../friends/:id/accept`
- `GET /api/social/friends`, `GET .../friends/streaks`
- `GET/POST /api/social/feed`, `GET/POST /api/social/chat/:peerUserId`
- بعد از submit درس → فید `lesson_complete`

### Why
انگیزه اجتماعی و دیدن پیشرفت دوستان.

## 2026-09-12 — فاز ۱۰ تمام شد (Mastery + Checkpoint)

### Added (Backend)
- `CourseMastery`, `CheckpointAttempt`; `lessons.lessonKind` (`standard|checkpoint|diagnostic`)
- `GET /api/mastery/courses/:courseId`
- Path unlock: یونیت ۲+ فقط با قبولی checkpoint قبلی یا ≥۱ درس بدون checkpoint
- Seed: آزمون یونیت ۱ = checkpoint

### Why
سنجش تسلط واقعی و دروازه پیشرفت.

## 2026-09-12 — فاز ۹ تمام شد (Leagues + Gems + Shop)

### Added (Backend)
- `UserWallet`, `GemTransaction`, `ShopItem`, `LeagueSeason`, `LeagueMembership`
- `GET /api/economy/wallet`, `GET .../shop`, `POST .../shop/:itemKey/buy`
- `GET /api/economy/leagues/current`, `GET .../leagues/leaderboard`
- بعد از submit: جم `2 + floor(xp/50)` + weekly XP لیگ
- Shop seed: streak_freeze (50), energy_pack_5 (30), xp_boost placeholder

### Why
اقتصاد جم و رقابت هفتگی.

## 2026-09-12 — فاز ۸ تمام شد (Gamification Core)

### Added (Backend)
- `UserGamification`: XP، استریک، فریز، قلب، Club، lessonsCompleted
- کوئست روزانه (۳ قالب؛ ریست با تاریخ UTC)
- نشان‌ها + pin؛ لوت‌باکس هر ۳ درس
- `GET /api/gamification`, `POST .../loot/:id/open`, `PATCH .../badges/:key/pin`
- بعد از submit نشست، XP/استریک/قلب/کوئست/نشان/لوت اعمال می‌شود

### Added (Flutter)
- صفحه «پیشرفت بازی» + HUD استریک/قلب/XP روی مسیر

### Why
انگیزه روزانه بدون تقلب کلاینت.

## 2026-09-12 — فاز ۷ تمام شد (Energy + Combo)

### Added (Backend)
- `UserEnergy` + `EnergyTransaction` (لجر ضدتقلب)
- Regen هر ۵ دقیقه تا سقف ۲۵ (قابل تنظیم با env)
- Burn ۱ انرژی هنگام `POST /lessons/:id/sessions`؛ بدون انرژی → `INSUFFICIENT_ENERGY`
- Combo: هر ۵ درست متوالی در submit → رول تصادفی ۱–۷ فقط روی سرور
- `GET /api/energy`

### Added (Flutter)
- نمایش انرژی روی مسیر یادگیری
- انیمیشن «کومبو!» در نتیجه آزمون وقتی سرور پاداش بدهد
- پیام واضح وقتی انرژی کافی نیست

### Why
سوخت بازی و پاداش تمرکز؛ کلاینت نمی‌تواند انرژی جعل کند.

## 2026-09-12 — فاز ۶ تمام شد (Progress و SRS)

### Added (Backend)
- موجودیت `ItemProgress` (skillScore + nextReviewAt + آمار)
- زمان‌بندی SRS در `src/progress/srs.ts` (ladder + ease)
- بعد از submit نشست، پیشرفت به‌روز می‌شود؛ غلط‌ها فوراً due می‌شوند
- تزریق تا ۳ تمرین مرور از بانک یونیت ۲ به نشست درس
- APIهای JWT: `GET /api/progress`, `GET /api/reviews`, `GET /api/progress/:itemKind/:itemId`
- `wordId` روی Exercise؛ seed بانک مرور SRS

### Added (Flutter)
- `ProgressRepository` + صفحه «پیشرفت و مرور»
- برچسب «مرور هوشمند» روی تمرین‌های تزریقی در Quiz

### Why
سیستم چیزهای سخت را یادش بماند و دوباره بپرسد.

## 2026-09-12 — فاز ۵ تمام شد (ماژول‌های تمرین)

### Added (Backend)
- انواع `QuestionType`: matching, cloze_typing, word_bank, translation, reorder, listening, speaking, image_word (+ multiple_choice)
- قرارداد content/answer برای هر نوع در `question.types.ts`
- grader سرور برای همه انواع در `exercise-grader.ts`
- seed آزمون با ۹ تمرین (هر نوع یکی)

### Added (Flutter)
- `ExerciseModuleRouter` و ماژول‌های تعاملی در `quiz/modules/exercise_modules.dart`
- QuizScreen از ماژول‌ها استفاده می‌کند؛ نوع ناشناخته بدون کرش

### Why
هر نوع سؤال لگو جدا باشد؛ نمره فقط سمت سرور.

### Notes
صوت واقعی، STT، و تصویر کامل عمداً برای فاز ۱۲ مانده‌اند (stub UI).

## 2026-09-12 — فاز ۴ تمام شد (Flutter ↔ API)

### Added (Flutter)
- `dio` + `ApiClient` با Bearer و refresh خودکار روی 401
- `CurriculumRepository` و `SessionRepository`
- `LearningPathScreen` از `GET /courses` + `/path` لود می‌کند
- مطالعه از `GET /units/:id` (واژه‌ها)
- آزمون: `POST /lessons/:id/sessions` سپس submit سرور
- حالت‌های loading / error / empty + دکمه تلاش دوباره
- `SampleData` فقط به‌عنوان legacy باقی ماند

### Changed (Backend)
- `GET /units/:id` حالا `exerciseCount` برای هر درس برمی‌گرداند

### Why
اپ باید thin client واقعی باشد، نه دموی آفلاین.

## 2026-09-12 — فاز ۳ تمام شد (Lesson Session / Thin Client)

### Added
- موجودیت‌های `LessonSession`, `SessionAttempt`
- APIهای JWT-only:
  - `POST /api/lessons/:lessonId/sessions` — شروع نشست، تمرین بدون answer
  - `GET /api/sessions/:sessionId`
  - `POST /api/sessions/:sessionId/submit` — نمره‌دهی سرور
- grader برای `multiple_choice`, `matching`, `cloze_typing`
- Rate limiting با `@nestjs/throttler` (سراسری + سقف سخت‌تر روی session)
- انقضای نشست بعد از ۲ ساعت؛ جلوگیری از submit دوباره

### Why
ضدتقلب و thin client: گوشی فقط UI است؛ مغز و جواب روی سرور می‌ماند.

## 2026-09-12 — فاز ۲ تمام شد (Curriculum دامنه-آزاد)

### Added
- موجودیت‌های `Course`, `Lesson`, `Exercise`
- `Section.courseId` و `Word.courseId` (واژه دارایی دوره)
- سلسله‌مراتب: Course → Section → Unit → Lesson → Exercise
- API خواندنی:
  - `GET /api/courses`
  - `GET /api/courses/:id`
  - `GET /api/courses/:id/path`
  - `GET /api/units/:unitId`
  - `GET /api/lessons/:lessonId` (بدون answer مگر `includeAnswers=1`)
- Seed کامل دوره کنکور + ۲ درس + ۳ تمرین + ۶ واژه + ۳ یونیت روی path
- `src/database/data-source.ts` + اسکریپت‌های migration برای آینده
- `Question` قدیمی deprecated ولی جدولش برای سازگاری مانده

### Why
موتور محتوا باید برای هر موضوعی کار کند، نه فقط زبان؛ و UI مسیر از API تغذیه شود.

## 2026-09-12 — فاز ۱ تمام شد (Auth و پروفایل)

### Added (Backend)
- موجودیت‌های `User`, `UserProfile`, `UserSettings`
- ماژول `auth`: register, login, refresh, logout, me, patch profile/settings
- JWT access + refresh با هش refresh روی DB
- `JwtAuthGuard` + Bearer در Swagger
- ValidationPipe سراسری و CORS
- متغیرهای `JWT_*` در `.env.example`

### Added (Flutter)
- `AuthGate` + صفحات Login / Register / Profile
- `TokenStorage` با `flutter_secure_storage`
- `AuthApi` برای تماس با سرور
- دکمه پروفایل روی مسیر یادگیری

### Why
بدون حساب کاربری، انرژی/پیشرفت/اجتماعی ممکن نیست.

## 2026-09-12 — فاز ۰ تمام شد

### Added
- `AGENTS.md` قانون کار ایجنت (خواندن اجباری + گزارش پایان فاز + اجازه فاز بعد)
- درخت `docs/`: INDEX، RESEARCH، PRD، ARCHITECTURE، ROADMAP، GLOSSARY، PROGRESS، BUGS، DECISIONS، API-CONTRACT
- ۱۸ فایل فاز: `docs/phases/PHASE-00` تا `PHASE-17` با هدف، چک‌لیست، DoD
- پوشش کامل قابلیت‌های `dolingo.txt` در PRD و نگاشت به فازها

### Why
تا هر پرامپت بداند کجاییم، چه چیزی باید ساخته شود، و قابلیت‌ها جا نمانند.

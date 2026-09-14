# Changelog

ثبت تغییرات مهم پروژه. جدیدترین بالا.

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

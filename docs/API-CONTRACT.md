# قرارداد API (API-CONTRACT)

> با پیشرفت فازها این سند و Swagger (`/api/docs`) هم‌تراز می‌شوند.

## الان موجود است

| Method | Path | Auth | توضیح |
|--------|------|------|--------|
| GET | `/api` | خیر | سلام API |
| GET | `/api/health` | خیر | `{ status: "ok" }` |
| GET | `/api/docs` | خیر | Swagger UI |
| POST | `/api/auth/register` | خیر | ثبت‌نام → tokens + user |
| POST | `/api/auth/login` | خیر | ورود → tokens + user |
| POST | `/api/auth/refresh` | خیر (body: refreshToken) | توکن جدید |
| POST | `/api/auth/logout` | Bearer | باطل کردن refresh |
| GET | `/api/auth/me` | Bearer | پروفایل + تنظیمات |
| PATCH | `/api/auth/me/profile` | Bearer | displayName, avatarUrl, bio |
| PATCH | `/api/auth/me/settings` | Bearer | اعلان‌ها |
| GET | `/api/courses` | خیر | لیست دوره‌های منتشرشده |
| GET | `/api/courses/:id` | خیر | دوره + sections/units |
| GET | `/api/courses/:id/path` | Bearer | نودهای مسیر (قفل checkpoint-aware) |
| GET | `/api/units/:unitId` | خیر | درس‌ها + واژه‌های مطالعه |
| GET | `/api/lessons/:lessonId` | خیر | تمرین‌ها؛ `?includeAnswers=1` برای جواب |
| GET | `/api/gamification` | Bearer | استریک، XP، قلب، کوئست، نشان، لوت |
| POST | `/api/gamification/loot/:lootId/open` | Bearer | باز کردن جعبه (پاداش سرور) |
| PATCH | `/api/gamification/badges/:badgeKey/pin` | Bearer | پین نشان `{ "pinned": true }` |
| GET | `/api/energy` | Bearer | موجودی انرژی (+ اعمال regen) |
| GET | `/api/progress` | Bearer | خلاصه skill + همه آیتم‌ها |
| GET | `/api/reviews` | Bearer | صف مرور سررسید (`?limit=`) |
| GET | `/api/progress/:itemKind/:itemId` | Bearer | یک آیتم (`word` یا `exercise`) |
| POST | `/api/lessons/:lessonId/sessions` | Bearer | شروع نشست موقت (بدون answer؛ ممکن است تمرین مرور تزریق شود) |
| GET | `/api/sessions/:sessionId` | Bearer | بازیابی نشست |
| POST | `/api/sessions/:sessionId/submit` | Bearer | ارسال پاسخ‌ها و نمره سرور |
| GET | `/api/economy/wallet` | Bearer | موجودی جم |
| GET | `/api/economy/shop` | Bearer | کاتالوگ فروشگاه |
| POST | `/api/economy/shop/:itemKey/buy` | Bearer | خرید با جم |
| GET | `/api/economy/leagues/current` | Bearer | لیگ هفتگی فعلی |
| GET | `/api/economy/leagues/leaderboard` | Bearer | لیدربورد ۵۰ نفر اول |
| GET | `/api/mastery/courses/:courseId` | Bearer | Mastery 0–100 |
| POST | `/api/social/friends/request` | Bearer | `{ "emailOrUserId": "..." }` |
| POST | `/api/social/friends/:id/accept` | Bearer | قبول درخواست |
| GET | `/api/social/friends` | Bearer | لیست دوستان |
| GET | `/api/social/friends/streaks` | Bearer | استریک دوستان |
| GET | `/api/social/feed` | Bearer | فید فعالیت |
| POST | `/api/social/feed` | Bearer | پست خود `{ "message": "..." }` |
| GET | `/api/social/chat/:peerUserId` | Bearer | تاریخچه چت |
| POST | `/api/social/chat/:peerUserId` | Bearer | `{ "body": "..." }` |

### نمونه submit

```json
POST /api/sessions/:sessionId/submit
{
  "answers": [
    { "exerciseId": "...", "response": { "correctOption": "رها کردن" } },
    { "exerciseId": "...", "response": { "pairs": { "abandon": "رها کردن" } } },
    { "exerciseId": "...", "response": { "blanks": { "blank_1": "diminish" } } }
  ]
}
```

### قرارداد jsonb تمرین‌ها (فاز ۵)

| type | content (برای کلاینت) | answer (فقط سرور / `includeAnswers=1`) | response در submit |
|------|------------------------|------------------------------------------|---------------------|
| `multiple_choice` | `{ options, stem? }` | `{ correctOption }` | `{ correctOption }` یا `{ selected }` |
| `matching` | `{ leftItems[], rightItems[] }` | `{ pairs: { left: right } }` | `{ pairs }` |
| `cloze_typing` | `{ text, blanks[{id,position}] }` | `{ blanks: { id: text } }` | `{ blanks }` |
| `word_bank` | `{ bank[], instruction? }` | `{ order[] }` | `{ order[] }` |
| `translation` | `{ direction, source }` | `{ texts[] }` | `{ text }` |
| `reorder` | `{ items[] }` | `{ order[] }` | `{ order[] }` |
| `listening` | `{ options[], audioUrl?, slowAudioUrl?, hint? }` | `{ correctOption }` | `{ correctOption }` |
| `speaking` | `{ prompt, targetText }` | `{ text }` | `{ text }` یا `{ transcript }` |
| `image_word` | `{ options[], imageUrl?, imageLabel? }` | `{ correctOption }` | `{ correctOption }` |

نوع ناشناخته در grader → غلط؛ در Flutter → پیام امن بدون کرش.

### Progress / SRS (فاز ۶)

- بعد از `submit`، برای هر تمرین با `wordId` (وگرنه خود exercise) رکورد `ItemProgress` به‌روز می‌شود.
- غلط → `nextReviewAt = الآن` (ورود به صف `/reviews`).
- درست → فاصله مرور طبق نردبان (۱۰د، ۱س، ۱ر، ۳ر، ۷ر، …) × ease.
- شروع نشست بعدی می‌تواند تا ۳ تمرین از بانک مرور (`isReview: true`) تزریق کند؛ IDها در `lesson_sessions.reviewExerciseIds` ذخیره می‌شوند.

### Energy / Combo (فاز ۷)

- کیف پول: `user_energy` — `balance`, `lastRegenAt`, سقف پیش‌فرض ۲۵، regen هر ۵ دقیقه ۱ واحد.
- شروع نشست درس ۱ انرژی می‌سوزاند و در `energy_transactions` با `lesson_start` ثبت می‌شود.
- بدون انرژی: HTTP 403 با `{ code: "INSUFFICIENT_ENERGY", energy: {...} }`.
- بعد از submit: هر ۵ درست متوالی → `combo_reward` با رول ۱–۷؛ پاسخ شامل `comboRewards[]` و `energy`.

پاسخ نمونه `GET /api/energy`:

```json
{
  "balance": 24,
  "cap": 25,
  "regenIntervalMinutes": 5,
  "nextRegenAt": "2026-09-12T12:00:00.000Z",
  "millisUntilNextRegen": 120000,
  "lessonCost": 1
}
```

### Gamification (فاز ۸)

- استریک روزانه (UTC)؛ غیبت بدون فریز → صفر؛ با فریز حفظ می‌شود.
- XP: ۱۰ به ازای هر درست + ۱۵ بونوس جلسه؛ قلب با غلط کم و با مرور درست برمی‌گردد.
- کوئست روزانه ۳ تایی؛ لوت هر ۳ درس؛ Club با استریک ۷ یا ۵۰۰ XP.
- submit پاسخ شامل `gamification`, `economy` (gems), `mastery`, `feed`.

### Economy / Leagues (فاز ۹)

- کیف جم: `user_wallets.gems`; لجر `gem_transactions` با reason (`lesson|quest|purchase|iap|admin`).
- بعد از submit: `gemsEarned = 2 + floor(xpGained/50)` + `weeklyXp` در لیگ.
- لیگ هفتگی UTC (دوشنبه)؛ پله Bronze→Diamond بر اساس XP هفته قبل.
- Shop seed: `streak_freeze` (50 جم), `energy_pack_5` (30 جم), `xp_boost` (placeholder).
- خرید بدون جم: HTTP 403 `{ code: "INSUFFICIENT_GEMS" }`.

### Mastery / Checkpoint (فاز ۱۰)

- `lessons.lessonKind`: `standard` | `checkpoint` | `diagnostic`.
- Checkpoint با `scorePercent >= 70` → `checkpoint_attempts.passed = true`.
- Mastery دوره = میانگین `skillScore` واژه‌های دوره.
- Path: یونیت ۱ همیشه active؛ یونیت N+1 فقط اگر checkpoint یونیت N قبول شده (یا بدون checkpoint و ≥۱ درس تمام).

### Social (فاز ۱۱)

- دوستی: `pending` → `accepted`؛ چت فقط بین دوستان accepted.
- فید شامل خود + دوستان؛ `lesson_complete` خودکار بعد از submit.

### Media (فاز ۱۲)

- فایل‌های static خارج از `/api`: مثلاً `GET /audio/abandon.wav`
- `Exercise.content.audioUrl` / `slowAudioUrl`: مسیر نسبی از ریشه host (بدون `/api`)
- Flutter: `ApiConfig.resolveMediaUrl('/audio/...')`

### Re-engagement (فاز ۱۳)

- `GET /api/reengagement/status` → `{ requiresDiagnostic, diagnosticLessonId, lastSeenAt, ... }`
- `POST /api/reengagement/diagnostic/complete` — یا خودکار بعد از submit درس `diagnostic`
- شروع نشست غیر-diagnostic وقتی `requiresDiagnostic=true`: HTTP 403 `{ code: "DIAGNOSTIC_REQUIRED" }`
- غیبت: `lastSeenAt` قدیمی‌تر از ۳ روز → `requiresDiagnostic=true` (روی `GET /auth/me` و شروع نشست)

### Admin (فاز ۱۴) — Bearer + role=admin

| Method | Path | توضیح |
|--------|------|--------|
| GET | `/api/admin/users` | لیست کاربران + energy balance |
| PATCH | `/api/admin/users/:id/ban` | `{ "banned": true }` |
| GET | `/api/admin/analytics` | userCount, sessionCount, avgScore, comboTxnCount |
| GET/POST/PATCH | `/api/admin/courses` | CMS دوره |
| GET/POST/PATCH | `/api/admin/lessons?courseId=` | CMS درس |
| GET/POST/PATCH | `/api/admin/exercises?lessonId=` | CMS تمرین |
| GET | `/api/admin/purchases` | لاگ خریدها (فاز ۱۷) |

### AI Pipeline (فاز ۱۵) — admin only

| Method | Path | توضیح |
|--------|------|--------|
| GET | `/api/admin/ai/jobs` | لیست jobها |
| POST | `/api/admin/ai/jobs` | `{ "sourceText": "..." }` |
| POST | `/api/admin/ai/jobs/:id/approve` | publish بعد از تأیید انسان |

وضعیت job: `uploaded → extracting → structuring → generating → awaiting_review → published | failed`

### Billing (فاز ۱۷)

| Method | Path | Auth | توضیح |
|--------|------|------|--------|
| POST | `/api/billing/verify` | Bearer | `{ productId, platform, receipt }` |
| GET | `/api/billing/me` | Bearer | اشتراک + خریدهای اخیر |

محصولات: `energy_pack_10`, `unlimited_1d`, `unlimited_1w`, `unlimited_1m`

- رسید خالی / `INVALID` / تکراری → رد
- `web_test`: رسید باید با `TEST.` شروع شود
- اشتراک unlimited فعال → `burnForLessonStart` skip می‌شود

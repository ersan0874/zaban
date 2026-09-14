# پیشرفت پروژه (PROGRESS)

> منبع حقیقت «تا کجا رسیدیم». ایجنت بعد از هر فاز این را آپدیت می‌کند.

## فاز فعال

**هیچ** — فازهای ۰–۱۷ تمام شدند.

## خلاصه وضعیت

| فاز | وضعیت | تاریخ اتمام | یادداشت |
|-----|--------|-------------|---------|
| 0 مستندات | **تمام** | 2026-09-12 | AGENTS + docs |
| 1 Auth | **تمام** | 2026-09-12 | JWT + پروفایل |
| 2 Curriculum | **تمام** | 2026-09-12 | Course→Exercise |
| 3 Session | **تمام** | 2026-09-12 | نشست + grading سرور |
| 4 Flutter wire | **تمام** | 2026-09-12 | dio + path/study/quiz از API |
| 5 Exercise modules | **تمام** | 2026-09-12 | ۹ نوع + grader + UI |
| 6 Progress/SRS | **تمام** | 2026-09-12 | skill + صف مرور + تزریق |
| 7 Energy/Combo | **تمام** | 2026-09-12 | burn + regen + combo سرور |
| 8 Gamification | **تمام** | 2026-09-12 | streak/XP/quests/badges/loot |
| 9 Leagues/Shop | **تمام** | 2026-09-12 | جم، لیگ هفتگی، فروشگاه |
| 10 Mastery/Checkpoint | **تمام** | 2026-09-12 | mastery + قفل path |
| 11 Social | **تمام** | 2026-09-12 | دوستان، فید، چت |
| 12 Media/Audio | **تمام** | 2026-09-12 | WAV static + listening + speaking UX |
| 13 Re-engagement | **تمام** | 2026-09-12 | diagnostic gate + settings |
| 14 Admin Panel | **تمام** | 2026-09-12 | Next.js + Nest admin API |
| 15 AI Pipeline | **تمام** | 2026-09-12 | AiJob + human approve |
| 16 DevOps | **تمام** | 2026-09-12 | Docker Compose + CI |
| 17 Monetization | **تمام** | 2026-09-12 | IAP verify + unlimited sub |

## تاریخچه گزارش‌ها

### 2026-09-12 — پایان فازهای ۱۴–۱۷

- پنل ادمین Next.js: کاربران، analytics، CMS، AI jobs، خریدها
- `User.role` + `User.banned`؛ seed `admin@zaban.local`
- خط لوله AI: extract → structure → generate → awaiting_review → publish
- Docker Compose (postgres, redis, api, admin, nginx, worker stub) + CI
- Billing: verify receipt، اشتراک unlimited، skip energy burn

### 2026-09-12 — پایان فاز ۱۳

آزمون بازگشت بعد از ۳ روز غیبت؛ gate نشست؛ تنظیم اعلان از پروفایل.

### 2026-09-12 — پایان فاز ۱۲

صوت listening از `/audio/`؛ speaking با نمره سرور؛ انیمیشن بازخورد quiz.

### 2026-09-12 — پایان فاز ۱۱

دوستان، فید فعالیت، چت ۱-به-۱، استریک دوستان از API.

### 2026-09-12 — پایان فاز ۱۰

Mastery دوره از skill واژه‌ها؛ checkpoint یونیت ۱؛ قفل path تا قبولی.

### 2026-09-12 — پایان فاز ۹

جم، لیگ هفتگی Bronze→Diamond، فروشگاه (فریز/انرژی)، لیدربورد Postgres.

### 2026-09-12 — پایان فاز ۸

استریک، قلب، XP، کوئست روزانه، نشان، لوت‌باکس، پرچم Club — همه از سرور.

### 2026-09-12 — پایان فاز ۷

انرژی با شارژ خودکار، مصرف هنگام شروع آزمون، پاداش کومبو فقط از سرور.

### 2026-09-12 — پایان فاز ۶

مهارت واژه، موعد مرور، صف `/reviews`، تزریق تمرین مرور به نشست بعدی.

### 2026-09-12 — پایان فاز ۵

همه انواع تمرین ماژولار (قرارداد + UI + نمره سرور).

### 2026-09-12 — پایان فاز ۴

Flutter از سرور واقعی می‌خواند؛ SampleData از مسیر اصلی خارج شد.

### 2026-09-12 — پایان فاز ۳

نشست درس و نمره‌دهی سرور.

### 2026-09-12 — پایان فاز ۲

ساختار دوره دامنه-آزاد.

### 2026-09-12 — پایان فاز ۱

Auth و پروفایل.

### 2026-09-12 — پایان فاز ۰

مستندات و فازبندی.

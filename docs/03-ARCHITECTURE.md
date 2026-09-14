# معماری سیستم Zaban

## فلسفه

1. **Thin Client:** اپ Flutter فقط UI و رندر الگوهاست؛ درس و جواب‌ها در APK ثابت نیستند.
2. **On-demand:** محتوای هر درس فقط با JWT معتبر در نشست موقت می‌آید.
3. **Server-side truth:** انرژی، XP، استریک، جم، صحت جواب فقط روی سرور قطعی می‌شود.
4. **Domain-agnostic:** موتور برای هر موضوع (زبان، پزشکی، …) بدون عوض کردن کلاینت کار می‌کند.
5. **Admin جدا:** Next.js در پوشه `admin/` روی همان API.

## سلسله‌مراتب محتوا

```text
Course
 └── Section (Chapter)
      └── Unit (Milestone / Path node)
           └── Lesson
                └── Exercise (type + content jsonb + answer server-side)
```

دارایی‌های قابل ارجاع: `Word` / Lexeme، Media assets.

## اجزای استقرار هدف

| سرویس | نقش |
|--------|-----|
| NestJS API | کلاینت موبایل + ادمین |
| Worker | OCR، Whisper، LLM، کارهای سنگین |
| PostgreSQL | داده پایدار |
| Redis | کش انرژی/لیگ/نشست + صف |
| Nginx/Caddy | SSL و روتینگ |
| Next.js Admin | بک‌آفیس |
| Flutter App | کلاینت کاربر |

## امنیت محتوا

- جواب خام تمرین به کلاینت لو نرود (یا فقط پس از submit برای توضیح).
- Rate limit روی شروع درس و submit.
- بدون scrape آسان از APK.

## وضعیت فعلی کد

- اسکلت Nest: Section/Unit/Word/Question + seed
- اسکلت Flutter: Path / Study / Quiz (نمونه محلی)
- هنوز Auth، Session، Redis، Admin، AI نیست

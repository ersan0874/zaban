# فاز ۱۳ — Re-engagement



## هدف

اگر چند روز نیامدی، اپ هوات را داشته باشد و کمکت کند برگردی.



## قابلیت‌ها

- [x] Dynamic App Icon — **مستند: پشتیبانی محدود**؛ stub در `dynamic_app_icon.dart`

- [x] تشخیص غیبت طولانی (`UserReentry`, ۳ روز)

- [x] Re-entry Diagnostic Test (`lessonKind=diagnostic`)

- [x] تزریق مرور SRS بعد از آزمون بازگشت (via `recordSessionResults` + inject در نشست بعد)

- [x] Push notifications تنظیم‌پذیر (PATCH settings از پروفایل)



## DoD

- [x] بعد از غیبت، آزمون بازگشت قبل از درس جدید می‌آید (`DIAGNOSTIC_REQUIRED`)

- [x] تنظیم اعلان از پروفایل اعمال می‌شود



## یادداشت Dynamic App Icon

iOS/Android/Web اکثراً بدون plugin اختصاصی از تغییر آیکون runtime پشتیبانی نمی‌کنند. UX اصلی: بنر آزمون بازگشت روی مسیر یادگیری.


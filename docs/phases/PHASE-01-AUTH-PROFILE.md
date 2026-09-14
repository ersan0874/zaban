# فاز ۱ — Auth و پروفایل

## هدف
کاربر بتواند ثبت‌نام/ورود کند و پروفایل و تنظیمات داشته باشد.

## قابلیت‌ها (زبان ساده)
- ساخت حساب
- ورود و خروج
- دیدن و ویرایش پروفایل
- تنظیم اعلان‌ها

## بک‌اند
- موجودیت: `User`, `UserProfile`, `UserSettings`
- JWT access + refresh
- مسیرها: register, login, refresh, logout, GET/PATCH me
- Swagger کامل برای auth

## موبایل
- صفحات Login / Register / Profile اسکلت
- ذخیره امن توکن

## خارج از محدوده
- لیگ، انرژی، چت، ادمین

## DoD
- [x] ثبت‌نام و ورود از API کار می‌کند
- [x] توکن محافظت‌شده است
- [x] پروفایل خوانده/ویرایش می‌شود
- [x] CHANGELOG + PROGRESS + API-CONTRACT آپدیت شده

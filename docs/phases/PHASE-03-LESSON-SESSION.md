# فاز ۳ — نشست درس و تحویل Thin Client

## هدف
وقتی کاربر درس را شروع می‌کند، سرور یک «بلیت موقت» بدهد و تمرین‌ها را بدون لو دادن جواب خام بفرستد.

## کارها
- [x] `POST /lessons/:id/sessions`
- [x] تحویل chunk تمرین‌ها بدون answer
- [x] `POST /sessions/:id/submit` با اعتبارسنجی سرور
- [x] `GET /sessions/:id`
- [x] Rate limit (Throttler) + JWT اجباری

## قابلیت‌ها
- On-demand chunking
- Server-side validation پایه (MC / matching / cloze)

## DoD
- [x] بدون توکن نمی‌شود درس گرفت (401)
- [x] submit فقط سمت سرور درست/غلط را قطعی می‌کند
- [x] مستندات API آپدیت شده

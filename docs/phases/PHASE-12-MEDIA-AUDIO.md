# فاز ۱۲ — Media و Audio



## هدف

صدا و تصویر واقعی برای تمرین شنیدن/گفتن و کاراکترها.



## قابلیت‌ها

- [x] ذخیره/سرو فایل تلفظ (`public/audio/`, Nest static)

- [x] سرعت آهسته listening (`abandon-slow.wav` + دکمه آهسته)

- [ ] تصاویر وکتور / کاراکتر (فاز بعد)

- [x] اتصال media به Exercise.content (`audioUrl`, `slowAudioUrl`)

- [x] انیمیشن بازخورد (burst بین سؤالات + نتیجه pass/retry)

- [x] تکمیل ماژول listening و speaking از فاز ۵



## DoD

- [x] حداقل یک درس با audio واقعی قابل پخش است

- [x] speaking یک مسیر ارزیابی (typed fallback + نمره سرور) دارد



## یادداشت پیاده‌سازی

- Flutter: `MediaPlayer` با HTML5 audio روی web؛ روی desktop/mobile IO از handler سیستم.

- `audioplayers` در pubspec نیست (محدودیت pub.dev در CI محلی) — قابل اضافه شدن بعداً.


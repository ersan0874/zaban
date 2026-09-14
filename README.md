# Zaban

اپ یادگیری واژگان انگلیسی برای کنکور ارشد — بک‌اند NestJS + موبایل Flutter + پنل ادمین Next.js.

## از کجا شروع کنیم؟

1. قانون ایجنت‌ها: [`AGENTS.md`](AGENTS.md)
2. پیشرفت واقعی: [`docs/PROGRESS.md`](docs/PROGRESS.md)
3. نقشه فازها: [`docs/04-ROADMAP.md`](docs/04-ROADMAP.md)
4. فهرست کامل اسناد: [`docs/00-INDEX.md`](docs/00-INDEX.md)

## ساختار

| پوشه | نقش |
|------|-----|
| `src/` | API NestJS |
| `mobile/` | اپ Flutter |
| `docs/` | پلن، فازها، باگ، تغییرات |
| `admin/` | پنل ادمین Next.js |

## اجرای سریع فعلی

```bash
# API
cp .env.example .env
npm install
npm run start:dev
# Swagger: http://localhost:3000/api/docs

# Flutter
cd mobile && flutter pub get && flutter run

# Admin (dev)
cd admin && cp .env.local.example .env.local && npm install && npm run dev
# http://localhost:3001 — login: admin@zaban.local / Admin1234!

# Full stack (Docker)
docker compose up --build
# nginx: http://localhost:8080/admin/  API: http://localhost:8080/api/
```

## SSL (production)

Place nginx behind certbot:

```bash
# Example: certbot --nginx -d yourdomain.com
# Update nginx/nginx.conf to listen 443 with ssl_certificate paths
```

See `nginx/nginx.conf` and `scripts/backup-db.sh` for reverse proxy and DB backup.

ریپو: https://github.com/ersan0874/zaban

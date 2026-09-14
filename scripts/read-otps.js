require('dotenv').config();
const { Client } = require('pg');

(async () => {
  const c = new Client({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 5432),
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_DATABASE || 'zaban',
  });
  await c.connect();
  const r = await c.query(
    'SELECT receiver, code, "expiresAt" FROM otps ORDER BY "expiresAt" DESC LIMIT 5',
  );
  console.log(JSON.stringify(r.rows, null, 2));
  await c.end();
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});

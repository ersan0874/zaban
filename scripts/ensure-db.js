require('dotenv').config();
const { Client } = require('pg');

(async () => {
  const admin = new Client({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 5432),
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: 'postgres',
  });
  await admin.connect();
  const dbName = process.env.DB_DATABASE || 'zaban';
  const r = await admin.query(
    'SELECT 1 FROM pg_database WHERE datname = $1',
    [dbName],
  );
  if (r.rowCount === 0) {
    await admin.query(`CREATE DATABASE "${dbName}"`);
    console.log(`created ${dbName}`);
  } else {
    console.log(`${dbName} exists`);
  }
  await admin.end();
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});

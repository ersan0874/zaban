import { DataSource } from 'typeorm';

/**
 * TypeORM CLI data source — ready for future migrations.
 * Dev still uses synchronize via AppModule; production should set DB_SYNC=false
 * and run migrations with this DataSource (env vars must be present).
 */
export default new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST ?? 'localhost',
  port: Number(process.env.DB_PORT ?? 5432),
  username: process.env.DB_USERNAME ?? 'postgres',
  password: process.env.DB_PASSWORD ?? 'postgres',
  database: process.env.DB_DATABASE ?? 'zaban',
  entities: ['src/**/*.entity.ts'],
  migrations: ['src/database/migrations/*.ts'],
  synchronize: false,
});

import { DataSource } from 'typeorm';

/**
 * TypeORM CLI data source — used for generating and running migrations.
 * Dev uses synchronize via AppModule; with DB_SYNC=false the app runs these
 * migrations on boot. Generate new ones with `npm run migration:generate`.
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

import { MigrationInterface, QueryRunner } from 'typeorm';

/** Energy per page + growing combo (ADR-016). */
export class EnergyPerPage1790970000001 implements MigrationInterface {
  name = 'EnergyPerPage1790970000001';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "user_energy" ADD "comboStreak" integer NOT NULL DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" ADD "steps" jsonb NOT NULL DEFAULT '{}'`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" ADD "comboRewards" jsonb NOT NULL DEFAULT '[]'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" DROP COLUMN "comboRewards"`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" DROP COLUMN "steps"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_energy" DROP COLUMN "comboStreak"`,
    );
  }
}

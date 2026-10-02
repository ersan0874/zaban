import { MigrationInterface, QueryRunner } from 'typeorm';

export class LateGrades1790970000000 implements MigrationInterface {
  name = 'LateGrades1790970000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "session_attempts" ADD "lateGradedAt" TIMESTAMP WITH TIME ZONE`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" ADD "lateGradeUnseen" boolean NOT NULL DEFAULT false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "session_attempts" DROP COLUMN "lateGradeUnseen"`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" DROP COLUMN "lateGradedAt"`,
    );
  }
}

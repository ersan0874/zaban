import { MigrationInterface, QueryRunner } from 'typeorm';

/** Lesson-by-lesson path with review exams and reward chests. */
export class PathExamsChests1791000000000 implements MigrationInterface {
  name = 'PathExamsChests1791000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" ADD "kind" character varying(16) NOT NULL DEFAULT 'lesson'`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" ADD "courseId" uuid`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" ADD "examPosition" integer`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" ADD "examTitle" character varying(255)`,
    );
    await queryRunner.query(
      `CREATE TABLE "path_milestones" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "courseId" uuid NOT NULL, "kind" character varying(16) NOT NULL, "position" integer NOT NULL, "scorePercent" integer, "done" boolean NOT NULL DEFAULT false, "rewards" jsonb NOT NULL DEFAULT '{}', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_c6d515099cebd0c5c929a718a1e" UNIQUE ("userId", "courseId", "kind", "position"), CONSTRAINT "PK_path_milestones" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `ALTER TABLE "path_milestones" ADD CONSTRAINT "FK_0d6e258da92fa93db9115961acc" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "path_milestones"`);
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" DROP COLUMN "examTitle"`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" DROP COLUMN "examPosition"`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" DROP COLUMN "courseId"`,
    );
    await queryRunner.query(`ALTER TABLE "lesson_sessions" DROP COLUMN "kind"`);
  }
}

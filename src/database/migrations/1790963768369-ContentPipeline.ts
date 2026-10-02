import { MigrationInterface, QueryRunner } from 'typeorm';

export class ContentPipeline1790963768369 implements MigrationInterface {
  name = 'ContentPipeline1790963768369';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "content_source_files" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "jobId" uuid NOT NULL, "order" integer NOT NULL, "originalName" character varying(255) NOT NULL, "mimeType" character varying(128) NOT NULL, "sizeBytes" integer NOT NULL, "storagePath" character varying(512) NOT NULL, "extractedMarkdown" text, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_3edd14ef67960b791172dfdc985" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "content_proposals" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "jobId" uuid NOT NULL, "order" integer NOT NULL, "title" character varying(255) NOT NULL, "rationale" text NOT NULL, "outline" jsonb NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_aa45be5c14ee4295784655a895c" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "content_jobs" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "title" character varying(255) NOT NULL, "status" character varying(32) NOT NULL DEFAULT 'extracting', "settings" jsonb NOT NULL, "sourceBlocks" jsonb NOT NULL DEFAULT '[]', "domain" character varying(100), "error" text, "pausedUntil" TIMESTAMP WITH TIME ZONE, "tokenUsage" jsonb NOT NULL DEFAULT '{"inputTokens":0,"outputTokens":0,"calls":0}', "selectedProposalId" uuid, "publishedCourseId" uuid, "createdBy" uuid, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_68db95082d076d5b6a89311bdbe" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "content_draft_lessons" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "jobId" uuid NOT NULL, "sectionOrder" integer NOT NULL, "sectionTitle" character varying(255) NOT NULL, "unitOrder" integer NOT NULL, "unitTitle" character varying(255) NOT NULL, "order" integer NOT NULL, "title" character varying(255) NOT NULL, "objective" text NOT NULL, "blockStart" integer NOT NULL, "blockEnd" integer NOT NULL, "status" character varying(16) NOT NULL DEFAULT 'pending', "notes" jsonb NOT NULL DEFAULT '[]', "keyTerms" jsonb NOT NULL DEFAULT '[]', "error" text, "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_5561bde9129350f64c04c6b5f54" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "content_draft_exercises" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "draftLessonId" uuid NOT NULL, "type" character varying(100) NOT NULL, "prompt" text NOT NULL, "order" integer NOT NULL, "content" jsonb NOT NULL, "answer" jsonb NOT NULL, "relatedTerm" character varying(255), "quality" character varying(16) NOT NULL DEFAULT 'ok', "qualityNote" text, CONSTRAINT "PK_d4f66a58bda96020925410d9f66" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(`ALTER TABLE "lessons" ADD "notes" jsonb`);
    await queryRunner.query(`ALTER TABLE "session_attempts" ADD "score" real`);
    await queryRunner.query(
      `ALTER TABLE "session_attempts" ADD "feedback" text`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" ADD "gradingStatus" character varying(16) NOT NULL DEFAULT 'graded'`,
    );
    await queryRunner.query(
      `ALTER TABLE "content_source_files" ADD CONSTRAINT "FK_2a7555223ca6d9d94b4e371febb" FOREIGN KEY ("jobId") REFERENCES "content_jobs"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "content_proposals" ADD CONSTRAINT "FK_7342cb8c4dae5b0c88555288122" FOREIGN KEY ("jobId") REFERENCES "content_jobs"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "content_draft_lessons" ADD CONSTRAINT "FK_b1103a12203cd20005c3808e6a9" FOREIGN KEY ("jobId") REFERENCES "content_jobs"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "content_draft_exercises" ADD CONSTRAINT "FK_63a3c07e358b6b0e55044ef25f8" FOREIGN KEY ("draftLessonId") REFERENCES "content_draft_lessons"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "content_draft_exercises" DROP CONSTRAINT "FK_63a3c07e358b6b0e55044ef25f8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "content_draft_lessons" DROP CONSTRAINT "FK_b1103a12203cd20005c3808e6a9"`,
    );
    await queryRunner.query(
      `ALTER TABLE "content_proposals" DROP CONSTRAINT "FK_7342cb8c4dae5b0c88555288122"`,
    );
    await queryRunner.query(
      `ALTER TABLE "content_source_files" DROP CONSTRAINT "FK_2a7555223ca6d9d94b4e371febb"`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" DROP COLUMN "gradingStatus"`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" DROP COLUMN "feedback"`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" DROP COLUMN "score"`,
    );
    await queryRunner.query(`ALTER TABLE "lessons" DROP COLUMN "notes"`);
    await queryRunner.query(`DROP TABLE "content_draft_exercises"`);
    await queryRunner.query(`DROP TABLE "content_draft_lessons"`);
    await queryRunner.query(`DROP TABLE "content_jobs"`);
    await queryRunner.query(`DROP TABLE "content_proposals"`);
    await queryRunner.query(`DROP TABLE "content_source_files"`);
  }
}

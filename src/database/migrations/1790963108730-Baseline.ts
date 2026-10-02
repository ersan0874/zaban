import { MigrationInterface, QueryRunner } from 'typeorm';

export class Baseline1790963108730 implements MigrationInterface {
  name = 'Baseline1790963108730';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "ai_jobs" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "status" character varying(32) NOT NULL DEFAULT 'uploaded', "sourceType" character varying(32) NOT NULL DEFAULT 'text', "sourceText" text NOT NULL, "resultJson" jsonb, "createdBy" uuid, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_895e59e4adb993a3f45dacb1d6b" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "otps" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "receiver" character varying(255) NOT NULL, "code" character varying(10) NOT NULL, "expiresAt" TIMESTAMP WITH TIME ZONE NOT NULL, CONSTRAINT "PK_91fef5ed60605b854a2115d2410" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "user_profiles" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "displayName" character varying(120) NOT NULL, "avatarUrl" character varying(500), "bio" character varying(300), CONSTRAINT "REL_8481388d6325e752cd4d7e26c6" UNIQUE ("userId"), CONSTRAINT "PK_1ec6662219f4605723f1e41b6cb" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "user_settings" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "notificationsEnabled" boolean NOT NULL DEFAULT true, "dailyReminderEnabled" boolean NOT NULL DEFAULT true, "marketingEmailsEnabled" boolean NOT NULL DEFAULT false, CONSTRAINT "REL_986a2b6d3c05eb4091bb8066f7" UNIQUE ("userId"), CONSTRAINT "PK_00f004f5922a0744d174530d639" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "users" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "email" character varying(255) NOT NULL, "passwordHash" character varying(255) NOT NULL, "refreshTokenHash" character varying(255), "role" character varying(16) NOT NULL DEFAULT 'user', "banned" boolean NOT NULL DEFAULT false, "level" character varying(32), "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email"), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "energy_subscriptions" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "plan" character varying(16) NOT NULL, "expiresAt" TIMESTAMP WITH TIME ZONE NOT NULL, "active" boolean NOT NULL DEFAULT true, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_869daa10d2ae88cb4ff815a04c8" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_02e6218b2dc3e9f97a5f6f66a7" ON "energy_subscriptions"  ("userId", "active") `,
    );
    await queryRunner.query(
      `CREATE TABLE "purchases" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "productId" character varying(64) NOT NULL, "platform" character varying(16) NOT NULL, "receipt" text NOT NULL, "status" character varying(16) NOT NULL DEFAULT 'pending', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_1d55032f37a34c6eceacbbca6b8" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_e90cff78ee1ed1127eb6064a2a" ON "purchases"  ("receipt") `,
    );
    await queryRunner.query(
      `CREATE TABLE "words" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "word" character varying(255) NOT NULL, "persianMeaning" character varying(500) NOT NULL, "synonyms" text array NOT NULL DEFAULT '{}', "examples" jsonb NOT NULL DEFAULT '[]', "courseId" uuid, "unitId" uuid, CONSTRAINT "UQ_38a98e41b6be0f379166dc2b58d" UNIQUE ("word"), CONSTRAINT "PK_feaf97accb69a7f355fa6f58a3d" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."questions_difficulty_enum" AS ENUM('easy', 'standard', 'hard')`,
    );
    await queryRunner.query(
      `CREATE TABLE "questions" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "unitId" uuid NOT NULL, "type" character varying(100) NOT NULL, "prompt" text NOT NULL, "content" jsonb NOT NULL, "answer" jsonb NOT NULL, "difficulty" "public"."questions_difficulty_enum", CONSTRAINT "PK_08a6d4b0f49ff300bf3a0ca60ac" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "exercises" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "lessonId" uuid NOT NULL, "type" character varying(100) NOT NULL, "prompt" text NOT NULL, "order" integer NOT NULL DEFAULT '0', "content" jsonb NOT NULL, "answer" jsonb NOT NULL, "wordId" uuid, CONSTRAINT "PK_c4c46f5fa89a58ba7c2d894e3c3" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "lessons" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "title" character varying(255) NOT NULL, "summary" text, "order" integer NOT NULL, "estimatedMinutes" integer NOT NULL DEFAULT '4', "lessonKind" character varying(32) NOT NULL DEFAULT 'standard', "unitId" uuid NOT NULL, CONSTRAINT "PK_9b9a8d455cac672d262d7275730" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "units" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "title" character varying(255) NOT NULL, "order" integer NOT NULL, "sectionId" uuid NOT NULL, CONSTRAINT "PK_5a8f2f064919b587d93936cb223" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "sections" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "title" character varying(255) NOT NULL, "order" integer NOT NULL, "courseId" uuid NOT NULL, CONSTRAINT "PK_f9749dd3bffd880a497d007e450" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "courses" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "title" character varying(255) NOT NULL, "description" text, "domain" character varying(100) NOT NULL DEFAULT 'language', "locale" character varying(16) NOT NULL DEFAULT 'fa', "order" integer NOT NULL DEFAULT '1', "isPublished" boolean NOT NULL DEFAULT true, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_3f70a487cc718ad8eda4e6d58c9" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "league_seasons" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "weekStart" character varying(10) NOT NULL, "tier" character varying(32) NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_bc50e739325e8e12b29357d7cb6" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_fef9187d9bdcf3d8c02cf16b17" ON "league_seasons"  ("weekStart", "tier") `,
    );
    await queryRunner.query(
      `CREATE TABLE "league_memberships" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "seasonId" uuid NOT NULL, "tier" character varying(32) NOT NULL, "weeklyXp" integer NOT NULL DEFAULT '0', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_7a6867afdcfc041a34fbc24e4e7" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_7ef4fcfa8401b91c9dd0cfbdab" ON "league_memberships"  ("seasonId", "weeklyXp") `,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_dcf5926624d89c02e8716a65d0" ON "league_memberships"  ("userId", "seasonId") `,
    );
    await queryRunner.query(
      `CREATE TABLE "gem_transactions" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "delta" integer NOT NULL, "balanceAfter" integer NOT NULL, "reason" character varying(32) NOT NULL, "referenceId" uuid, "meta" jsonb NOT NULL DEFAULT '{}', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_e35383915a8f0e7ba2d95c81457" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_12f3d0326b8b243685a5c155aa" ON "gem_transactions"  ("userId", "createdAt") `,
    );
    await queryRunner.query(
      `CREATE TABLE "shop_items" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "key" character varying(64) NOT NULL, "title" character varying(255) NOT NULL, "description" text, "priceGems" integer NOT NULL, "effectType" character varying(32) NOT NULL, "effectPayload" jsonb NOT NULL DEFAULT '{}', "active" boolean NOT NULL DEFAULT true, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_d7378a7b780ab9b048ff4559e79" UNIQUE ("key"), CONSTRAINT "PK_413571c2dd7b80fd08551cf7726" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "user_wallets" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "gems" integer NOT NULL DEFAULT '0', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_b91f761672f6cf3a714593e6bdd" UNIQUE ("userId"), CONSTRAINT "REL_b91f761672f6cf3a714593e6bd" UNIQUE ("userId"), CONSTRAINT "PK_f98089275dcfc65d59b1d347167" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "user_energy" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "balance" integer NOT NULL DEFAULT '0', "lastRegenAt" TIMESTAMP WITH TIME ZONE NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_f0c3b5e76e97684fe7f08028863" UNIQUE ("userId"), CONSTRAINT "REL_f0c3b5e76e97684fe7f0802886" UNIQUE ("userId"), CONSTRAINT "PK_8911a36c6ac36c254c4632bb775" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "energy_transactions" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "delta" integer NOT NULL, "balanceAfter" integer NOT NULL, "reason" character varying(64) NOT NULL, "referenceId" uuid, "meta" jsonb NOT NULL DEFAULT '{}', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_deb79bff38342cff33217525c45" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_ea20fe8eaa8a93944fe4e0d0b4" ON "energy_transactions"  ("userId", "createdAt") `,
    );
    await queryRunner.query(
      `CREATE TABLE "daily_quests" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "questDate" character varying(10) NOT NULL, "questKey" character varying(64) NOT NULL, "title" character varying(255) NOT NULL, "progress" integer NOT NULL DEFAULT '0', "target" integer NOT NULL, "rewardXp" integer NOT NULL DEFAULT '0', "rewardQuestPoints" integer NOT NULL DEFAULT '0', "completed" boolean NOT NULL DEFAULT false, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_3ed47cc4d3b3eeba932fb800dfd" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_9f93e2c818c4be8d9d9196770b" ON "daily_quests"  ("userId", "questDate", "questKey") `,
    );
    await queryRunner.query(
      `CREATE TABLE "loot_boxes" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "opened" boolean NOT NULL DEFAULT false, "rewards" jsonb NOT NULL DEFAULT '{}', "sourceSessionId" uuid, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "openedAt" TIMESTAMP WITH TIME ZONE, CONSTRAINT "PK_fc2488231b8ea777005320e65d8" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "user_badges" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "badgeKey" character varying(64) NOT NULL, "title" character varying(255) NOT NULL, "pinned" boolean NOT NULL DEFAULT false, "earnedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_0ca139216824d745a930065706a" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_a8a4893f1f1016465ce30cb31a" ON "user_badges"  ("userId", "badgeKey") `,
    );
    await queryRunner.query(
      `CREATE TABLE "user_gamification" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "xp" integer NOT NULL DEFAULT '0', "streakCount" integer NOT NULL DEFAULT '0', "lastActiveDate" character varying(10), "streakFreezeCount" integer NOT NULL DEFAULT '0', "hearts" integer NOT NULL DEFAULT '5', "heartsCap" integer NOT NULL DEFAULT '5', "lessonsCompleted" integer NOT NULL DEFAULT '0', "clubUnlocked" boolean NOT NULL DEFAULT false, "questPoints" integer NOT NULL DEFAULT '0', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_4f2db3f62e0aaa6a40540e7c27e" UNIQUE ("userId"), CONSTRAINT "REL_4f2db3f62e0aaa6a40540e7c27" UNIQUE ("userId"), CONSTRAINT "PK_db92d24015cda11113d1a3cad80" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "checkpoint_attempts" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "unitId" uuid NOT NULL, "lessonId" uuid NOT NULL, "scorePercent" integer NOT NULL, "passed" boolean NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_dd050bc4db11acb573826020561" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_25ce67e68cf33b28c83d8c7506" ON "checkpoint_attempts"  ("userId", "unitId", "passed") `,
    );
    await queryRunner.query(
      `CREATE TABLE "course_mastery" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "courseId" uuid NOT NULL, "score" integer NOT NULL DEFAULT '0', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_63a10cb93a32407c9f4fd7e0288" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_fd13e11eeb0e19082dabdcc308" ON "course_mastery"  ("userId", "courseId") `,
    );
    await queryRunner.query(
      `CREATE TABLE "item_progress" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "itemKind" character varying(32) NOT NULL, "itemId" uuid NOT NULL, "label" character varying(255), "skillScore" integer NOT NULL DEFAULT '0', "repetitions" integer NOT NULL DEFAULT '0', "easeFactor" double precision NOT NULL DEFAULT '2.5', "intervalMinutes" integer NOT NULL DEFAULT '10', "nextReviewAt" TIMESTAMP WITH TIME ZONE NOT NULL, "lastReviewedAt" TIMESTAMP WITH TIME ZONE, "lastWasCorrect" boolean, "totalCorrect" integer NOT NULL DEFAULT '0', "totalIncorrect" integer NOT NULL DEFAULT '0', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_d14d0a0cf3d276e3610e2cad038" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_6aed559970ee34dafbea9b0f0a" ON "item_progress"  ("userId", "nextReviewAt") `,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_fe4bf3b55421fef6957e0717b7" ON "item_progress"  ("userId", "itemKind", "itemId") `,
    );
    await queryRunner.query(
      `CREATE TABLE "user_reentry" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "lastSeenAt" TIMESTAMP WITH TIME ZONE, "requiresDiagnostic" boolean NOT NULL DEFAULT false, "diagnosticCompletedAt" TIMESTAMP WITH TIME ZONE, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "UQ_8028d4a0596f0ca7cc6af39821a" UNIQUE ("userId"), CONSTRAINT "REL_8028d4a0596f0ca7cc6af39821" UNIQUE ("userId"), CONSTRAINT "PK_caea41f480ea5f55d14198054b9" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "session_attempts" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "sessionId" uuid NOT NULL, "exerciseId" uuid NOT NULL, "response" jsonb NOT NULL, "isCorrect" boolean NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_c6c28535e58eba1b8a8d1a16841" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "lesson_sessions" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "lessonId" uuid NOT NULL, "status" character varying(32) NOT NULL DEFAULT 'active', "expiresAt" TIMESTAMP WITH TIME ZONE NOT NULL, "correctCount" integer NOT NULL DEFAULT '0', "totalCount" integer NOT NULL DEFAULT '0', "reviewExerciseIds" uuid array NOT NULL DEFAULT '{}', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "completedAt" TIMESTAMP WITH TIME ZONE, CONSTRAINT "PK_07c712bd1808a8a198d9ff2ef38" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "chat_messages" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "fromUserId" uuid NOT NULL, "toUserId" uuid NOT NULL, "body" text NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_40c55ee0e571e268b0d3cd37d10" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_38c782e04e46331dba3e9bd475" ON "chat_messages"  ("fromUserId", "toUserId", "createdAt") `,
    );
    await queryRunner.query(
      `CREATE TABLE "feed_items" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "type" character varying(64) NOT NULL, "message" text NOT NULL, "meta" jsonb NOT NULL DEFAULT '{}', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_9a33f003d604fbe4060d75c7be2" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_b5376b32c4f2d7fb166b977190" ON "feed_items"  ("userId", "createdAt") `,
    );
    await queryRunner.query(
      `CREATE TABLE "friendships" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "requesterId" uuid NOT NULL, "addresseeId" uuid NOT NULL, "status" character varying(32) NOT NULL DEFAULT 'pending', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_08af97d0be72942681757f07bc8" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_ae267b922c295ac548dd498e54" ON "friendships"  ("requesterId", "addresseeId") `,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."subscriptions_plantype_enum" AS ENUM('monthly', 'three_months', 'yearly')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."subscriptions_status_enum" AS ENUM('active', 'expired', 'canceled')`,
    );
    await queryRunner.query(
      `CREATE TABLE "subscriptions" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "planType" "public"."subscriptions_plantype_enum" NOT NULL, "status" "public"."subscriptions_status_enum" NOT NULL DEFAULT 'active', "startDate" TIMESTAMP WITH TIME ZONE NOT NULL, "endDate" TIMESTAMP WITH TIME ZONE NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_a87248d73155605cf782be9ee5e" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."payment_transactions_plantype_enum" AS ENUM('monthly', 'three_months', 'yearly')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."payment_transactions_status_enum" AS ENUM('pending', 'paid', 'failed')`,
    );
    await queryRunner.query(
      `CREATE TABLE "payment_transactions" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "planType" "public"."payment_transactions_plantype_enum" NOT NULL, "amount" integer NOT NULL, "authority" character varying(64) NOT NULL, "status" "public"."payment_transactions_status_enum" NOT NULL DEFAULT 'pending', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_f8f50e29561204d682a724570a4" UNIQUE ("authority"), CONSTRAINT "PK_d32b3c6b0d2c1d22604cbcc8c49" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "user_stats" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "hearts" integer NOT NULL DEFAULT '5', "gems" integer NOT NULL DEFAULT '100', "streak" integer NOT NULL DEFAULT '0', "lastActivityDate" date, CONSTRAINT "UQ_1ef59671d5359ff63ae55ae4efa" UNIQUE ("userId"), CONSTRAINT "REL_1ef59671d5359ff63ae55ae4ef" UNIQUE ("userId"), CONSTRAINT "PK_f55fb5b508e96b05303efae93e5" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_profiles" ADD CONSTRAINT "FK_8481388d6325e752cd4d7e26c6d" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_settings" ADD CONSTRAINT "FK_986a2b6d3c05eb4091bb8066f78" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "energy_subscriptions" ADD CONSTRAINT "FK_75422514ba888bbf3f7e96f1802" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "purchases" ADD CONSTRAINT "FK_341f0dbe584866284359f30f3da" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "words" ADD CONSTRAINT "FK_33e86ffbdd91258f2517ea1258a" FOREIGN KEY ("courseId") REFERENCES "courses"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "words" ADD CONSTRAINT "FK_1fd478f756a31b65fc75bcdc5ea" FOREIGN KEY ("unitId") REFERENCES "units"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "questions" ADD CONSTRAINT "FK_414e08235e7e73108d0faa50689" FOREIGN KEY ("unitId") REFERENCES "units"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "exercises" ADD CONSTRAINT "FK_c7a7b90ae6ce91a6d8bcf09b8b6" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "lessons" ADD CONSTRAINT "FK_7c9fe457707c44ae26910acf6c5" FOREIGN KEY ("unitId") REFERENCES "units"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "units" ADD CONSTRAINT "FK_73a7fc02f6a2a8274ba29bb4d49" FOREIGN KEY ("sectionId") REFERENCES "sections"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "sections" ADD CONSTRAINT "FK_0fc0dc8ce98e7dc47c273f85e3d" FOREIGN KEY ("courseId") REFERENCES "courses"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "league_memberships" ADD CONSTRAINT "FK_288ed4a3a64ff35dfc6a1cd1fc4" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "league_memberships" ADD CONSTRAINT "FK_993feccc43b351ad2f00fd36466" FOREIGN KEY ("seasonId") REFERENCES "league_seasons"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "gem_transactions" ADD CONSTRAINT "FK_0f6896267e7c0c641fe0347813f" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_wallets" ADD CONSTRAINT "FK_b91f761672f6cf3a714593e6bdd" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_energy" ADD CONSTRAINT "FK_f0c3b5e76e97684fe7f08028863" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "energy_transactions" ADD CONSTRAINT "FK_c2668295d9b3928ed3caa0b2895" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "daily_quests" ADD CONSTRAINT "FK_29123b806391ab598a519d88408" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "loot_boxes" ADD CONSTRAINT "FK_67ad2e9cf31448048f3e2c85e72" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_badges" ADD CONSTRAINT "FK_7043fd1cb64ec3f5ebdb878966c" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_gamification" ADD CONSTRAINT "FK_4f2db3f62e0aaa6a40540e7c27e" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "checkpoint_attempts" ADD CONSTRAINT "FK_3e89f21a5658a98cd7ee8d0822d" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "course_mastery" ADD CONSTRAINT "FK_968b757dddace641e8a0009d8f5" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "item_progress" ADD CONSTRAINT "FK_fcdc1d398e226d93c474b09d4e5" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_reentry" ADD CONSTRAINT "FK_8028d4a0596f0ca7cc6af39821a" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" ADD CONSTRAINT "FK_460b3456ae5551887e100b2d170" FOREIGN KEY ("sessionId") REFERENCES "lesson_sessions"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" ADD CONSTRAINT "FK_8150f9260747c4a9d824bc0cfeb" FOREIGN KEY ("exerciseId") REFERENCES "exercises"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" ADD CONSTRAINT "FK_777153ba7a59646d60c83dad894" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" ADD CONSTRAINT "FK_d969da930bf78b0f7186682ae2b" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "chat_messages" ADD CONSTRAINT "FK_9ee145fd616227448de53646872" FOREIGN KEY ("fromUserId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "chat_messages" ADD CONSTRAINT "FK_fbfdf0b8ee76855843441cc7551" FOREIGN KEY ("toUserId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "feed_items" ADD CONSTRAINT "FK_07a33241222746e607986a18af4" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "friendships" ADD CONSTRAINT "FK_4f47ed519abe1ced044af260420" FOREIGN KEY ("requesterId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "friendships" ADD CONSTRAINT "FK_c6ee540bba37d2b09b12dddd282" FOREIGN KEY ("addresseeId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "subscriptions" ADD CONSTRAINT "FK_fbdba4e2ac694cf8c9cecf4dc84" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "payment_transactions" ADD CONSTRAINT "FK_60b852936ca1e980cce98d977a2" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_stats" ADD CONSTRAINT "FK_1ef59671d5359ff63ae55ae4efa" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "user_stats" DROP CONSTRAINT "FK_1ef59671d5359ff63ae55ae4efa"`,
    );
    await queryRunner.query(
      `ALTER TABLE "payment_transactions" DROP CONSTRAINT "FK_60b852936ca1e980cce98d977a2"`,
    );
    await queryRunner.query(
      `ALTER TABLE "subscriptions" DROP CONSTRAINT "FK_fbdba4e2ac694cf8c9cecf4dc84"`,
    );
    await queryRunner.query(
      `ALTER TABLE "friendships" DROP CONSTRAINT "FK_c6ee540bba37d2b09b12dddd282"`,
    );
    await queryRunner.query(
      `ALTER TABLE "friendships" DROP CONSTRAINT "FK_4f47ed519abe1ced044af260420"`,
    );
    await queryRunner.query(
      `ALTER TABLE "feed_items" DROP CONSTRAINT "FK_07a33241222746e607986a18af4"`,
    );
    await queryRunner.query(
      `ALTER TABLE "chat_messages" DROP CONSTRAINT "FK_fbfdf0b8ee76855843441cc7551"`,
    );
    await queryRunner.query(
      `ALTER TABLE "chat_messages" DROP CONSTRAINT "FK_9ee145fd616227448de53646872"`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" DROP CONSTRAINT "FK_d969da930bf78b0f7186682ae2b"`,
    );
    await queryRunner.query(
      `ALTER TABLE "lesson_sessions" DROP CONSTRAINT "FK_777153ba7a59646d60c83dad894"`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" DROP CONSTRAINT "FK_8150f9260747c4a9d824bc0cfeb"`,
    );
    await queryRunner.query(
      `ALTER TABLE "session_attempts" DROP CONSTRAINT "FK_460b3456ae5551887e100b2d170"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_reentry" DROP CONSTRAINT "FK_8028d4a0596f0ca7cc6af39821a"`,
    );
    await queryRunner.query(
      `ALTER TABLE "item_progress" DROP CONSTRAINT "FK_fcdc1d398e226d93c474b09d4e5"`,
    );
    await queryRunner.query(
      `ALTER TABLE "course_mastery" DROP CONSTRAINT "FK_968b757dddace641e8a0009d8f5"`,
    );
    await queryRunner.query(
      `ALTER TABLE "checkpoint_attempts" DROP CONSTRAINT "FK_3e89f21a5658a98cd7ee8d0822d"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_gamification" DROP CONSTRAINT "FK_4f2db3f62e0aaa6a40540e7c27e"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_badges" DROP CONSTRAINT "FK_7043fd1cb64ec3f5ebdb878966c"`,
    );
    await queryRunner.query(
      `ALTER TABLE "loot_boxes" DROP CONSTRAINT "FK_67ad2e9cf31448048f3e2c85e72"`,
    );
    await queryRunner.query(
      `ALTER TABLE "daily_quests" DROP CONSTRAINT "FK_29123b806391ab598a519d88408"`,
    );
    await queryRunner.query(
      `ALTER TABLE "energy_transactions" DROP CONSTRAINT "FK_c2668295d9b3928ed3caa0b2895"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_energy" DROP CONSTRAINT "FK_f0c3b5e76e97684fe7f08028863"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_wallets" DROP CONSTRAINT "FK_b91f761672f6cf3a714593e6bdd"`,
    );
    await queryRunner.query(
      `ALTER TABLE "gem_transactions" DROP CONSTRAINT "FK_0f6896267e7c0c641fe0347813f"`,
    );
    await queryRunner.query(
      `ALTER TABLE "league_memberships" DROP CONSTRAINT "FK_993feccc43b351ad2f00fd36466"`,
    );
    await queryRunner.query(
      `ALTER TABLE "league_memberships" DROP CONSTRAINT "FK_288ed4a3a64ff35dfc6a1cd1fc4"`,
    );
    await queryRunner.query(
      `ALTER TABLE "sections" DROP CONSTRAINT "FK_0fc0dc8ce98e7dc47c273f85e3d"`,
    );
    await queryRunner.query(
      `ALTER TABLE "units" DROP CONSTRAINT "FK_73a7fc02f6a2a8274ba29bb4d49"`,
    );
    await queryRunner.query(
      `ALTER TABLE "lessons" DROP CONSTRAINT "FK_7c9fe457707c44ae26910acf6c5"`,
    );
    await queryRunner.query(
      `ALTER TABLE "exercises" DROP CONSTRAINT "FK_c7a7b90ae6ce91a6d8bcf09b8b6"`,
    );
    await queryRunner.query(
      `ALTER TABLE "questions" DROP CONSTRAINT "FK_414e08235e7e73108d0faa50689"`,
    );
    await queryRunner.query(
      `ALTER TABLE "words" DROP CONSTRAINT "FK_1fd478f756a31b65fc75bcdc5ea"`,
    );
    await queryRunner.query(
      `ALTER TABLE "words" DROP CONSTRAINT "FK_33e86ffbdd91258f2517ea1258a"`,
    );
    await queryRunner.query(
      `ALTER TABLE "purchases" DROP CONSTRAINT "FK_341f0dbe584866284359f30f3da"`,
    );
    await queryRunner.query(
      `ALTER TABLE "energy_subscriptions" DROP CONSTRAINT "FK_75422514ba888bbf3f7e96f1802"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_settings" DROP CONSTRAINT "FK_986a2b6d3c05eb4091bb8066f78"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user_profiles" DROP CONSTRAINT "FK_8481388d6325e752cd4d7e26c6d"`,
    );
    await queryRunner.query(`DROP TABLE "user_stats"`);
    await queryRunner.query(`DROP TABLE "payment_transactions"`);
    await queryRunner.query(
      `DROP TYPE "public"."payment_transactions_status_enum"`,
    );
    await queryRunner.query(
      `DROP TYPE "public"."payment_transactions_plantype_enum"`,
    );
    await queryRunner.query(`DROP TABLE "subscriptions"`);
    await queryRunner.query(`DROP TYPE "public"."subscriptions_status_enum"`);
    await queryRunner.query(`DROP TYPE "public"."subscriptions_plantype_enum"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_ae267b922c295ac548dd498e54"`,
    );
    await queryRunner.query(`DROP TABLE "friendships"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_b5376b32c4f2d7fb166b977190"`,
    );
    await queryRunner.query(`DROP TABLE "feed_items"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_38c782e04e46331dba3e9bd475"`,
    );
    await queryRunner.query(`DROP TABLE "chat_messages"`);
    await queryRunner.query(`DROP TABLE "lesson_sessions"`);
    await queryRunner.query(`DROP TABLE "session_attempts"`);
    await queryRunner.query(`DROP TABLE "user_reentry"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_fe4bf3b55421fef6957e0717b7"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_6aed559970ee34dafbea9b0f0a"`,
    );
    await queryRunner.query(`DROP TABLE "item_progress"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_fd13e11eeb0e19082dabdcc308"`,
    );
    await queryRunner.query(`DROP TABLE "course_mastery"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_25ce67e68cf33b28c83d8c7506"`,
    );
    await queryRunner.query(`DROP TABLE "checkpoint_attempts"`);
    await queryRunner.query(`DROP TABLE "user_gamification"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_a8a4893f1f1016465ce30cb31a"`,
    );
    await queryRunner.query(`DROP TABLE "user_badges"`);
    await queryRunner.query(`DROP TABLE "loot_boxes"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_9f93e2c818c4be8d9d9196770b"`,
    );
    await queryRunner.query(`DROP TABLE "daily_quests"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_ea20fe8eaa8a93944fe4e0d0b4"`,
    );
    await queryRunner.query(`DROP TABLE "energy_transactions"`);
    await queryRunner.query(`DROP TABLE "user_energy"`);
    await queryRunner.query(`DROP TABLE "user_wallets"`);
    await queryRunner.query(`DROP TABLE "shop_items"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_12f3d0326b8b243685a5c155aa"`,
    );
    await queryRunner.query(`DROP TABLE "gem_transactions"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_dcf5926624d89c02e8716a65d0"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_7ef4fcfa8401b91c9dd0cfbdab"`,
    );
    await queryRunner.query(`DROP TABLE "league_memberships"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_fef9187d9bdcf3d8c02cf16b17"`,
    );
    await queryRunner.query(`DROP TABLE "league_seasons"`);
    await queryRunner.query(`DROP TABLE "courses"`);
    await queryRunner.query(`DROP TABLE "sections"`);
    await queryRunner.query(`DROP TABLE "units"`);
    await queryRunner.query(`DROP TABLE "lessons"`);
    await queryRunner.query(`DROP TABLE "exercises"`);
    await queryRunner.query(`DROP TABLE "questions"`);
    await queryRunner.query(`DROP TYPE "public"."questions_difficulty_enum"`);
    await queryRunner.query(`DROP TABLE "words"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_e90cff78ee1ed1127eb6064a2a"`,
    );
    await queryRunner.query(`DROP TABLE "purchases"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_02e6218b2dc3e9f97a5f6f66a7"`,
    );
    await queryRunner.query(`DROP TABLE "energy_subscriptions"`);
    await queryRunner.query(`DROP TABLE "users"`);
    await queryRunner.query(`DROP TABLE "user_settings"`);
    await queryRunner.query(`DROP TABLE "user_profiles"`);
    await queryRunner.query(`DROP TABLE "otps"`);
    await queryRunner.query(`DROP TABLE "ai_jobs"`);
  }
}

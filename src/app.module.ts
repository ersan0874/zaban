import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CoursesModule } from './courses/courses.module';
import { LessonsModule } from './lessons/lessons.module';
import { ExercisesModule } from './exercises/exercises.module';
import { SessionsModule } from './sessions/sessions.module';
import { SectionsModule } from './sections/sections.module';
import { UnitsModule } from './units/units.module';
import { WordsModule } from './words/words.module';
import { QuestionsModule } from './questions/questions.module';
import { ProgressModule } from './progress/progress.module';
import { EnergyModule } from './energy/energy.module';
import { GamificationModule } from './gamification/gamification.module';
import { EconomyModule } from './economy/economy.module';
import { MasteryModule } from './mastery/mastery.module';
import { SocialModule } from './social/social.module';
import { ReengagementModule } from './reengagement/reengagement.module';
import { AdminModule } from './admin/admin.module';
import { AiModule } from './ai/ai.module';
import { BillingModule } from './billing/billing.module';
import { Course } from './courses/entities/course.entity';
import { Section } from './sections/entities/section.entity';
import { Unit } from './units/entities/unit.entity';
import { Word } from './words/entities/word.entity';
import { Lesson } from './lessons/entities/lesson.entity';
import { Exercise } from './exercises/entities/exercise.entity';
import { User } from './users/entities/user.entity';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60_000,
        limit: 120,
      },
    ]),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres' as const,
        host: configService.get<string>('DB_HOST', 'localhost'),
        port: configService.get<number>('DB_PORT', 5432),
        username: configService.get<string>('DB_USERNAME', 'postgres'),
        password: configService.get<string>('DB_PASSWORD', 'postgres'),
        database: configService.get<string>('DB_DATABASE', 'zaban'),
        autoLoadEntities: true,
        synchronize: configService.get<string>('DB_SYNC', 'true') === 'true',
      }),
    }),
    TypeOrmModule.forFeature([
      User,
      Course,
      Section,
      Unit,
      Word,
      Lesson,
      Exercise,
    ]),
    UsersModule,
    AuthModule,
    CoursesModule,
    LessonsModule,
    ExercisesModule,
    SessionsModule,
    SectionsModule,
    UnitsModule,
    WordsModule,
    QuestionsModule,
    ProgressModule,
    EnergyModule,
    GamificationModule,
    EconomyModule,
    MasteryModule,
    SocialModule,
    ReengagementModule,
    AdminModule,
    AiModule,
    BillingModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}

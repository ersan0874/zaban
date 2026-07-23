import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SectionsModule } from './sections/sections.module';
import { UnitsModule } from './units/units.module';
import { WordsModule } from './words/words.module';
import { QuestionsModule } from './questions/questions.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PlacementTestModule } from './placement-test/placement-test.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { Section } from './sections/entities/section.entity';
import { Unit } from './units/entities/unit.entity';
import { Word } from './words/entities/word.entity';
import { Question } from './questions/entities/question.entity';
import { User } from './users/entities/user.entity';
import { UserStats } from './users/entities/user-stats.entity';
import { Otp } from './auth/entities/otp.entity';
import { Subscription } from './subscriptions/entities/subscription.entity';
import { PaymentTransaction } from './subscriptions/entities/payment-transaction.entity';


@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
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
      Section,
      Unit,
      Word,
      Question,
      User,
      UserStats,
      Otp,
      Subscription,
      PaymentTransaction,
    ]),
    SectionsModule,
    UnitsModule,
    WordsModule,
    QuestionsModule,
    UsersModule,
    AuthModule,
    PlacementTestModule,
    SubscriptionsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

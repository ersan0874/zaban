import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SectionsModule } from './sections/sections.module';
import { UnitsModule } from './units/units.module';
import { WordsModule } from './words/words.module';
import { QuestionsModule } from './questions/questions.module';
import { Section } from './sections/entities/section.entity';
import { Unit } from './units/entities/unit.entity';
import { Word } from './words/entities/word.entity';
import { Question } from './questions/entities/question.entity';

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
    TypeOrmModule.forFeature([Section, Unit, Word, Question]),
    SectionsModule,
    UnitsModule,
    WordsModule,
    QuestionsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

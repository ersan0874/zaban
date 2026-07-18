import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Word } from './entities/word.entity';
import { WordsController } from './words.controller';
import { WordsService } from './words.service';

@Module({
  imports: [TypeOrmModule.forFeature([Word])],
  controllers: [WordsController],
  providers: [WordsService],
  exports: [WordsService, TypeOrmModule],
})
export class WordsModule {}

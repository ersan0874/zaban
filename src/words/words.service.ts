import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Word } from './entities/word.entity';

@Injectable()
export class WordsService {
  constructor(
    @InjectRepository(Word)
    private readonly wordRepository: Repository<Word>,
  ) {}
}

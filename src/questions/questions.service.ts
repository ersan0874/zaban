import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Question } from './entities/question.entity';
import {
  QuestionDifficulty,
  QuestionType,
} from './types/question.types';

const PLACEMENT_QUESTION_COUNT = 10;

@Injectable()
export class QuestionsService {
  constructor(
    @InjectRepository(Question)
    private readonly questionRepository: Repository<Question>,
  ) {}

  async findPlacementQuestions(limit = PLACEMENT_QUESTION_COUNT): Promise<
    Array<Omit<Question, 'answer'>>
  > {
    const questions = await this.questionRepository.find({
      where: {
        difficulty: In([
          QuestionDifficulty.STANDARD,
          QuestionDifficulty.HARD,
        ]),
        type: QuestionType.MULTIPLE_CHOICE,
      },
      order: { id: 'ASC' },
      take: limit,
    });

    return questions.map(({ answer: _answer, ...question }) => question);
  }

  async findByIds(ids: string[]): Promise<Question[]> {
    if (ids.length === 0) {
      return [];
    }

    return this.questionRepository.find({
      where: { id: In(ids) },
    });
  }

  countPlacementQuestions(): Promise<number> {
    return this.questionRepository.count({
      where: {
        difficulty: In([
          QuestionDifficulty.STANDARD,
          QuestionDifficulty.HARD,
        ]),
        type: QuestionType.MULTIPLE_CHOICE,
      },
    });
  }
}

import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { QuestionsService } from '../questions/questions.service';
import { Question } from '../questions/entities/question.entity';
import {
  QuestionAnswer,
  QuestionType,
} from '../questions/types/question.types';
import { User, UserLevel } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { PlacementAnswerDto } from './dto/submit-placement.dto';

export interface PlacementSubmitResult {
  score: number;
  total: number;
  percentage: number;
  level: UserLevel;
  user: Omit<User, 'password'>;
}

@Injectable()
export class PlacementTestService {
  constructor(
    private readonly questionsService: QuestionsService,
    private readonly usersService: UsersService,
  ) {}

  getQuestions() {
    return this.questionsService.findPlacementQuestions();
  }

  async submit(
    user: User,
    answers: PlacementAnswerDto[],
  ): Promise<PlacementSubmitResult> {
    const questionIds = answers.map((item) => item.questionId);
    const questions = await this.questionsService.findByIds(questionIds);

    if (questions.length !== answers.length) {
      throw new BadRequestException('One or more question IDs are invalid');
    }

    const questionMap = new Map(questions.map((q) => [q.id, q]));
    let score = 0;

    for (const item of answers) {
      const question = questionMap.get(item.questionId);
      if (!question) {
        throw new NotFoundException(`Question ${item.questionId} not found`);
      }

      if (this.isAnswerCorrect(question, item.answer)) {
        score++;
      }
    }

    const total = answers.length;
    const percentage = total === 0 ? 0 : Math.round((score / total) * 100);
    const level = this.resolveLevel(percentage);

    user.level = level;
    const updatedUser = await this.usersService.save(user);

    return {
      score,
      total,
      percentage,
      level,
      user: updatedUser,
    };
  }

  private resolveLevel(percentage: number): UserLevel {
    if (percentage < 40) {
      return UserLevel.BEGINNER;
    }
    if (percentage <= 70) {
      return UserLevel.INTERMEDIATE;
    }
    return UserLevel.ADVANCED;
  }

  private isAnswerCorrect(
    question: Question,
    submitted: string | Record<string, unknown>,
  ): boolean {
    switch (question.type) {
      case QuestionType.MULTIPLE_CHOICE:
        return this.checkMultipleChoice(question.answer, submitted);
      case QuestionType.MATCHING:
        return this.checkMatching(question.answer, submitted);
      case QuestionType.CLOZE_TYPING:
        return this.checkClozeTyping(question.answer, submitted);
      default:
        return false;
    }
  }

  private checkMultipleChoice(
    correct: QuestionAnswer,
    submitted: string | Record<string, unknown>,
  ): boolean {
    if (typeof correct !== 'object' || correct === null || Array.isArray(correct)) {
      return false;
    }

    const correctOption = (correct as { correctOption?: string }).correctOption;
    return (
      typeof submitted === 'string' &&
      correctOption !== undefined &&
      submitted.trim() === correctOption.trim()
    );
  }

  private checkMatching(
    correct: QuestionAnswer,
    submitted: string | Record<string, unknown>,
  ): boolean {
    if (typeof correct !== 'object' || correct === null || Array.isArray(correct)) {
      return false;
    }
    if (typeof submitted !== 'object' || submitted === null || Array.isArray(submitted)) {
      return false;
    }

    const correctPairs = (correct as { pairs?: Record<string, string> }).pairs ?? {};
    const submittedPairs = submitted as Record<string, string>;

    const keys = Object.keys(correctPairs);
    if (keys.length === 0) {
      return false;
    }

    return keys.every(
      (key) => submittedPairs[key]?.trim() === correctPairs[key]?.trim(),
    );
  }

  private checkClozeTyping(
    correct: QuestionAnswer,
    submitted: string | Record<string, unknown>,
  ): boolean {
    if (typeof correct !== 'object' || correct === null || Array.isArray(correct)) {
      return false;
    }
    if (typeof submitted !== 'object' || submitted === null || Array.isArray(submitted)) {
      return false;
    }

    const correctBlanks =
      (correct as { blanks?: Record<string, string> }).blanks ?? {};
    const submittedBlanks = submitted as Record<string, string>;

    const keys = Object.keys(correctBlanks);
    if (keys.length === 0) {
      return false;
    }

    return keys.every(
      (key) =>
        submittedBlanks[key]?.trim().toLowerCase() ===
        correctBlanks[key]?.trim().toLowerCase(),
    );
  }
}

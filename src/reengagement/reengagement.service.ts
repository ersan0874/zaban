import { ForbiddenException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Lesson, LessonKind } from '../lessons/entities/lesson.entity';
import { UserReentry } from './entities/user-reentry.entity';

const ABSENCE_MS = 3 * 24 * 60 * 60 * 1000;

@Injectable()
export class ReengagementService {
  constructor(
    @InjectRepository(UserReentry)
    private readonly reentryRepository: Repository<UserReentry>,
    @InjectRepository(Lesson)
    private readonly lessonRepository: Repository<Lesson>,
  ) {}

  async recordActivity(userId: string): Promise<UserReentry> {
    let row = await this.reentryRepository.findOne({ where: { userId } });
    const now = new Date();

    if (!row) {
      return this.reentryRepository.save(
        this.reentryRepository.create({
          userId,
          lastSeenAt: now,
          requiresDiagnostic: false,
          diagnosticCompletedAt: null,
        }),
      );
    }

    if (
      row.lastSeenAt &&
      now.getTime() - row.lastSeenAt.getTime() > ABSENCE_MS
    ) {
      row.requiresDiagnostic = true;
    }

    row.lastSeenAt = now;
    return this.reentryRepository.save(row);
  }

  async getStatus(userId: string) {
    const row = await this.recordActivity(userId);
    const diagnosticLesson = await this.lessonRepository.findOne({
      where: { lessonKind: LessonKind.DIAGNOSTIC },
      order: { order: 'ASC' },
    });

    return {
      requiresDiagnostic: row.requiresDiagnostic,
      lastSeenAt: row.lastSeenAt,
      diagnosticCompletedAt: row.diagnosticCompletedAt,
      diagnosticLessonId: diagnosticLesson?.id ?? null,
      diagnosticLessonTitle: diagnosticLesson?.title ?? null,
      absenceThresholdDays: 3,
    };
  }

  async assertCanStartLesson(userId: string, lesson: Lesson): Promise<void> {
    const row = await this.recordActivity(userId);
    if (
      row.requiresDiagnostic &&
      lesson.lessonKind !== LessonKind.DIAGNOSTIC
    ) {
      throw new ForbiddenException({
        code: 'DIAGNOSTIC_REQUIRED',
        message:
          'Complete the re-entry diagnostic before starting a new lesson.',
      });
    }
  }

  async completeDiagnostic(userId: string): Promise<UserReentry> {
    let row = await this.reentryRepository.findOne({ where: { userId } });
    const now = new Date();

    if (!row) {
      row = this.reentryRepository.create({
        userId,
        lastSeenAt: now,
        requiresDiagnostic: false,
        diagnosticCompletedAt: now,
      });
    } else {
      row.requiresDiagnostic = false;
      row.diagnosticCompletedAt = now;
      row.lastSeenAt = now;
    }

    return this.reentryRepository.save(row);
  }
}

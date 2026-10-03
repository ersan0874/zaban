import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { In, QueryFailedError, Repository } from 'typeorm';
import { CoursesService } from '../courses/courses.service';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { SessionsService } from '../sessions/sessions.service';
import { EnergyService } from '../energy/energy.service';
import { EnergyTxnReason } from '../energy/entities/energy-transaction.entity';
import { EconomyService } from '../economy/economy.service';
import { GemTxnReason } from '../economy/entities/gem-transaction.entity';
import { GamificationService } from '../gamification/gamification.service';
import {
  PathMilestone,
  PathMilestoneKind,
} from './entities/path-milestone.entity';
import {
  buildPathItems,
  PathItem,
  pickExamExercises,
  rollChestRewards,
} from './path-items';
import { examQuestionsPerLesson, pathRules } from './path.config';

@Injectable()
export class PathService {
  constructor(
    @InjectRepository(Lesson)
    private readonly lessonRepository: Repository<Lesson>,
    @InjectRepository(Exercise)
    private readonly exerciseRepository: Repository<Exercise>,
    @InjectRepository(PathMilestone)
    private readonly milestoneRepository: Repository<PathMilestone>,
    private readonly coursesService: CoursesService,
    private readonly sessionsService: SessionsService,
    private readonly energyService: EnergyService,
    private readonly economyService: EconomyService,
    private readonly gamificationService: GamificationService,
    private readonly config: ConfigService,
  ) {}

  async startExam(userId: string, courseId: string, position: number) {
    const exam = await this.findItem(userId, courseId, 'exam', position);
    if (exam.kind !== 'exam') throw new NotFoundException('Exam not found');
    if (exam.status === 'locked') {
      throw new ForbiddenException('Finish the lessons before this exam');
    }
    const exercises = await this.exerciseRepository.find({
      where: { lessonId: In(exam.lessonIds) },
    });
    const picked = pickExamExercises(
      exercises,
      exam.lessonIds,
      examQuestionsPerLesson(this.config),
    );
    const anchorLesson = await this.lessonRepository.findOne({
      where: { id: exam.lessonIds[exam.lessonIds.length - 1] },
    });
    if (!anchorLesson) throw new NotFoundException('Lesson not found');
    return this.sessionsService.startExamSession(userId, {
      courseId,
      position,
      title: exam.title,
      anchorLesson,
      exercises: picked,
    });
  }

  async openChest(userId: string, courseId: string, position: number) {
    const chest = await this.findItem(userId, courseId, 'chest', position);
    if (chest.status === 'completed') {
      throw new ConflictException('Chest already opened');
    }
    if (chest.status === 'locked') {
      throw new ForbiddenException('Finish the lessons before this chest');
    }

    const rewards = rollChestRewards();
    // The unique row is the claim: a second tap cannot pay out twice.
    try {
      await this.milestoneRepository.insert({
        userId,
        courseId,
        kind: PathMilestoneKind.CHEST,
        position,
        done: true,
        rewards,
      });
    } catch (err) {
      if (err instanceof QueryFailedError) {
        throw new ConflictException('Chest already opened');
      }
      throw err;
    }

    const energy = await this.energyService.grant(
      userId,
      rewards.energy,
      EnergyTxnReason.LOOT_BOX,
      { courseId, chestPosition: position },
    );
    const wallet = await this.economyService.grantGems(
      userId,
      rewards.gems,
      GemTxnReason.CHEST,
      null,
      { courseId, chestPosition: position },
    );
    const gamification = await this.gamificationService.grantRewards(
      userId,
      rewards,
    );
    if (rewards.xp > 0) {
      await this.economyService.addWeeklyXp(userId, rewards.xp);
    }
    return { position, rewards, energy, gems: wallet.gems, gamification };
  }

  private async findItem(
    userId: string,
    courseId: string,
    kind: 'exam' | 'chest',
    position: number,
  ): Promise<PathItem> {
    if (!Number.isInteger(position) || position < 1) {
      throw new BadRequestException('Invalid position');
    }
    const lessons = await this.coursesService.getPathLessons(courseId);
    const items = buildPathItems(
      lessons,
      await this.coursesService.loadPathProgress(courseId, userId, lessons),
      pathRules(this.config),
    );
    const item = items.find(
      (i) => i.kind === kind && 'position' in i && i.position === position,
    );
    if (!item) {
      throw new NotFoundException(
        kind === 'exam' ? 'Exam not found' : 'Chest not found',
      );
    }
    return item;
  }
}

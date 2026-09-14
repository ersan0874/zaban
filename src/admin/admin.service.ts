import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { UserEnergy } from '../energy/entities/user-energy.entity';
import {
  EnergyTransaction,
  EnergyTxnReason,
} from '../energy/entities/energy-transaction.entity';
import { LessonSession } from '../sessions/entities/lesson-session.entity';
import { Course } from '../courses/entities/course.entity';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Exercise } from '../exercises/entities/exercise.entity';
import { CreateCourseDto } from './dto/create-course.dto';
import { UpdateCourseDto } from './dto/update-course.dto';
import { CreateLessonDto } from './dto/create-lesson.dto';
import { UpdateLessonDto } from './dto/update-lesson.dto';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(UserEnergy)
    private readonly energyRepository: Repository<UserEnergy>,
    @InjectRepository(EnergyTransaction)
    private readonly energyTxnRepository: Repository<EnergyTransaction>,
    @InjectRepository(LessonSession)
    private readonly sessionRepository: Repository<LessonSession>,
    @InjectRepository(Course)
    private readonly courseRepository: Repository<Course>,
    @InjectRepository(Lesson)
    private readonly lessonRepository: Repository<Lesson>,
    @InjectRepository(Exercise)
    private readonly exerciseRepository: Repository<Exercise>,
  ) {}

  async listUsers() {
    const users = await this.usersRepository.find({
      order: { createdAt: 'DESC' },
      relations: { profile: true },
    });

    const energyRows = await this.energyRepository.find();
    const energyByUser = new Map(energyRows.map((e) => [e.userId, e.balance]));

    return users.map((u) => ({
      id: u.id,
      email: u.email,
      role: u.role,
      banned: u.banned,
      displayName: u.profile?.displayName ?? null,
      createdAt: u.createdAt,
      energyBalance: energyByUser.get(u.id) ?? null,
    }));
  }

  async setUserBanned(userId: string, banned: boolean) {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    user.banned = banned;
    await this.usersRepository.save(user);
    return { id: user.id, banned: user.banned };
  }

  async getAnalytics() {
    const [userCount, sessionCount, comboTxnCount] = await Promise.all([
      this.usersRepository.count(),
      this.sessionRepository.count(),
      this.energyTxnRepository.count({
        where: { reason: EnergyTxnReason.COMBO_REWARD },
      }),
    ]);

    const avgRow = await this.sessionRepository
      .createQueryBuilder('s')
      .select('AVG(CASE WHEN s.totalCount > 0 THEN s.correctCount::float / s.totalCount ELSE 0 END)', 'avgScore')
      .where('s.status = :status', { status: 'completed' })
      .getRawOne<{ avgScore: string | null }>();

    return {
      userCount,
      sessionCount,
      avgScore: avgRow?.avgScore ? parseFloat(avgRow.avgScore) : 0,
      comboTxnCount,
    };
  }

  listCourses() {
    return this.courseRepository.find({ order: { order: 'ASC' } });
  }

  async createCourse(dto: CreateCourseDto) {
    const course = this.courseRepository.create({
      title: dto.title,
      description: dto.description ?? null,
      domain: dto.domain ?? 'language',
      locale: dto.locale ?? 'fa',
      order: dto.order ?? 0,
      isPublished: dto.isPublished ?? false,
    });
    return this.courseRepository.save(course);
  }

  async updateCourse(id: string, dto: UpdateCourseDto) {
    const course = await this.courseRepository.findOne({ where: { id } });
    if (!course) throw new NotFoundException('Course not found');
    Object.assign(course, dto);
    return this.courseRepository.save(course);
  }

  async listLessonsByCourse(courseId: string) {
    const course = await this.courseRepository.findOne({
      where: { id: courseId },
      relations: { sections: { units: { lessons: true } } },
    });
    if (!course) throw new NotFoundException('Course not found');

    const lessons = (course.sections ?? [])
      .flatMap((s) => s.units ?? [])
      .flatMap((u) => u.lessons ?? [])
      .sort((a, b) => a.order - b.order);

    return lessons.map((l) => ({
      id: l.id,
      title: l.title,
      summary: l.summary,
      order: l.order,
      unitId: l.unitId,
      estimatedMinutes: l.estimatedMinutes,
      lessonKind: l.lessonKind,
    }));
  }

  async createLesson(dto: CreateLessonDto) {
    const lesson = this.lessonRepository.create({
      unitId: dto.unitId,
      title: dto.title,
      summary: dto.summary ?? null,
      order: dto.order ?? 0,
      estimatedMinutes: dto.estimatedMinutes ?? 4,
    });
    return this.lessonRepository.save(lesson);
  }

  async updateLesson(id: string, dto: UpdateLessonDto) {
    const lesson = await this.lessonRepository.findOne({ where: { id } });
    if (!lesson) throw new NotFoundException('Lesson not found');
    Object.assign(lesson, dto);
    return this.lessonRepository.save(lesson);
  }

  async listExercisesByLesson(lessonId: string) {
    const exercises = await this.exerciseRepository.find({
      where: { lessonId },
      order: { order: 'ASC' },
    });
    return exercises;
  }

  async createExercise(dto: CreateExerciseDto) {
    const exercise = this.exerciseRepository.create({
      lessonId: dto.lessonId,
      type: dto.type,
      prompt: dto.prompt,
      order: dto.order ?? 0,
      content: dto.content,
      answer: dto.answer,
      wordId: dto.wordId ?? null,
    });
    return this.exerciseRepository.save(exercise);
  }

  async updateExercise(id: string, dto: UpdateExerciseDto) {
    const exercise = await this.exerciseRepository.findOne({ where: { id } });
    if (!exercise) throw new NotFoundException('Exercise not found');
    Object.assign(exercise, dto);
    return this.exerciseRepository.save(exercise);
  }
}

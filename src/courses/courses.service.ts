import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { Course } from './entities/course.entity';
import { Section } from '../sections/entities/section.entity';
import { Unit } from '../units/entities/unit.entity';
import { Lesson, LessonKind } from '../lessons/entities/lesson.entity';
import { Word } from '../words/entities/word.entity';
import { MasteryService } from '../mastery/mastery.service';
import {
  LessonSession,
  LessonSessionKind,
  LessonSessionStatus,
} from '../sessions/entities/lesson-session.entity';
import {
  PathMilestone,
  PathMilestoneKind,
} from '../path/entities/path-milestone.entity';
import { buildPathItems, PathLessonInput } from '../path/path-items';
import { pathRules } from '../path/path.config';

@Injectable()
export class CoursesService {
  constructor(
    @InjectRepository(Course)
    private readonly courseRepository: Repository<Course>,
    @InjectRepository(Section)
    private readonly sectionRepository: Repository<Section>,
    @InjectRepository(Unit)
    private readonly unitRepository: Repository<Unit>,
    @InjectRepository(Lesson)
    private readonly lessonRepository: Repository<Lesson>,
    @InjectRepository(Word)
    private readonly wordRepository: Repository<Word>,
    @InjectRepository(LessonSession)
    private readonly sessionRepository: Repository<LessonSession>,
    @InjectRepository(PathMilestone)
    private readonly milestoneRepository: Repository<PathMilestone>,
    private readonly masteryService: MasteryService,
    private readonly config: ConfigService,
  ) {}

  listPublished() {
    return this.courseRepository.find({
      where: { isPublished: true },
      order: { order: 'ASC' },
    });
  }

  async getCourse(id: string) {
    const course = await this.courseRepository.findOne({
      where: { id },
      relations: {
        sections: {
          units: true,
        },
      },
    });
    if (!course) {
      throw new NotFoundException('Course not found');
    }

    course.sections = (course.sections ?? []).sort((a, b) => a.order - b.order);
    for (const section of course.sections) {
      section.units = (section.units ?? []).sort((a, b) => a.order - b.order);
    }
    return course;
  }

  /**
   * Linear learning path nodes (units) for the zigzag UI.
   */
  async getPath(courseId: string, userId?: string) {
    const course = await this.courseRepository.findOne({
      where: { id: courseId, isPublished: true },
    });
    if (!course) {
      throw new NotFoundException('Course not found');
    }

    const sections = await this.sectionRepository.find({
      where: { courseId },
      relations: { units: { lessons: true } },
    });

    const sortedSections = sections.sort((a, b) => a.order - b.order);
    const orderedUnits = sortedSections.flatMap((section) =>
      (section.units ?? []).slice().sort((a, b) => a.order - b.order),
    );

    const statusMap = await this.masteryService.computePathStatuses(
      userId,
      orderedUnits,
    );

    const pathNodes = orderedUnits.map((unit) => {
      const section = sortedSections.find((s) => s.id === unit.sectionId)!;
      return {
        unitId: unit.id,
        title: unit.title,
        order: unit.order,
        sectionId: section.id,
        sectionTitle: section.title,
        lessonCount: unit.lessons?.length ?? 0,
        status: statusMap.get(unit.id) ?? 'locked',
      };
    });

    const lessons = this.orderedPathLessons(sortedSections, orderedUnits);
    const items = buildPathItems(
      lessons,
      await this.loadPathProgress(courseId, userId, lessons),
      pathRules(this.config),
    );

    return {
      course: {
        id: course.id,
        title: course.title,
        description: course.description,
        domain: course.domain,
        locale: course.locale,
      },
      nodes: pathNodes,
      items,
    };
  }

  /** Every lesson of the course in path order (diagnostics stay off it). */
  async getPathLessons(courseId: string): Promise<PathLessonInput[]> {
    const sections = await this.sectionRepository.find({
      where: { courseId },
      relations: { units: { lessons: true } },
    });
    const sortedSections = sections.sort((a, b) => a.order - b.order);
    const orderedUnits = sortedSections.flatMap((section) =>
      (section.units ?? []).slice().sort((a, b) => a.order - b.order),
    );
    return this.orderedPathLessons(sortedSections, orderedUnits);
  }

  async loadPathProgress(
    courseId: string,
    userId: string | undefined,
    lessons: PathLessonInput[],
  ) {
    if (!userId || lessons.length === 0) {
      return {
        completedLessonIds: new Set<string>(),
        passedExamPositions: new Set<number>(),
        openedChestPositions: new Set<number>(),
      };
    }
    const done = await this.sessionRepository.find({
      select: { lessonId: true },
      where: {
        userId,
        kind: LessonSessionKind.LESSON,
        status: LessonSessionStatus.COMPLETED,
        lessonId: In(lessons.map((l) => l.id)),
      },
    });
    const milestones = await this.milestoneRepository.find({
      where: { userId, courseId, done: true },
    });
    const positions = (kind: PathMilestoneKind) =>
      new Set(milestones.filter((m) => m.kind === kind).map((m) => m.position));
    return {
      completedLessonIds: new Set(done.map((s) => s.lessonId)),
      passedExamPositions: positions(PathMilestoneKind.EXAM),
      openedChestPositions: positions(PathMilestoneKind.CHEST),
    };
  }

  private orderedPathLessons(
    sections: Section[],
    units: Array<Unit & { lessons?: Lesson[] }>,
  ): PathLessonInput[] {
    return units.flatMap((unit) => {
      const section = sections.find((s) => s.id === unit.sectionId);
      return (unit.lessons ?? [])
        .filter((l) => l.lessonKind !== LessonKind.DIAGNOSTIC)
        .sort((a, b) => a.order - b.order)
        .map((l) => ({
          id: l.id,
          title: l.title,
          unitId: unit.id,
          unitTitle: unit.title,
          sectionTitle: section?.title ?? null,
        }));
    });
  }

  async getUnitDetail(unitId: string) {
    const unit = await this.unitRepository.findOne({
      where: { id: unitId },
      relations: {
        section: true,
        lessons: { exercises: true },
        words: true,
      },
    });
    if (!unit) {
      throw new NotFoundException('Unit not found');
    }

    const lessons = (unit.lessons ?? [])
      .slice()
      .sort((a, b) => a.order - b.order);

    return {
      id: unit.id,
      title: unit.title,
      order: unit.order,
      sectionId: unit.sectionId,
      sectionTitle: unit.section?.title ?? null,
      lessons: lessons.map((l) => ({
        id: l.id,
        title: l.title,
        summary: l.summary,
        order: l.order,
        estimatedMinutes: l.estimatedMinutes,
        lessonKind: l.lessonKind,
        exerciseCount: l.exercises?.length ?? 0,
      })),
      words: (unit.words ?? []).map((w) => ({
        id: w.id,
        word: w.word,
        persianMeaning: w.persianMeaning,
        synonyms: w.synonyms,
        examples: w.examples,
      })),
    };
  }

  async getLesson(lessonId: string, opts?: { includeAnswers?: boolean }) {
    const lesson = await this.lessonRepository.findOne({
      where: { id: lessonId },
      relations: { exercises: true, unit: true },
    });
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    const includeAnswers = opts?.includeAnswers === true;
    const exercises = (lesson.exercises ?? [])
      .slice()
      .sort((a, b) => a.order - b.order);

    return {
      id: lesson.id,
      title: lesson.title,
      summary: lesson.summary,
      order: lesson.order,
      estimatedMinutes: lesson.estimatedMinutes,
      unitId: lesson.unitId,
      exercises: exercises.map((ex) => ({
        id: ex.id,
        type: ex.type,
        prompt: ex.prompt,
        order: ex.order,
        content: ex.content,
        ...(includeAnswers ? { answer: ex.answer } : {}),
      })),
    };
  }
}

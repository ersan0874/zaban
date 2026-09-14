import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Course } from './entities/course.entity';
import { Section } from '../sections/entities/section.entity';
import { Unit } from '../units/entities/unit.entity';
import { Lesson } from '../lessons/entities/lesson.entity';
import { Word } from '../words/entities/word.entity';
import { MasteryService } from '../mastery/mastery.service';

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
    private readonly masteryService: MasteryService,
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

    return {
      course: {
        id: course.id,
        title: course.title,
        description: course.description,
        domain: course.domain,
        locale: course.locale,
      },
      nodes: pathNodes,
    };
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

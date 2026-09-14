import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from './users/entities/user.entity';
import { Course } from './courses/entities/course.entity';
import { Section } from './sections/entities/section.entity';
import { Unit } from './units/entities/unit.entity';
import { Word } from './words/entities/word.entity';
import { Lesson, LessonKind } from './lessons/entities/lesson.entity';
import { Exercise } from './exercises/entities/exercise.entity';
import { QuestionType } from './questions/types/question.types';

@Injectable()
export class AppService implements OnModuleInit {
  private readonly logger = new Logger(AppService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Course)
    private readonly courseRepository: Repository<Course>,
    @InjectRepository(Section)
    private readonly sectionRepository: Repository<Section>,
    @InjectRepository(Unit)
    private readonly unitRepository: Repository<Unit>,
    @InjectRepository(Word)
    private readonly wordRepository: Repository<Word>,
    @InjectRepository(Lesson)
    private readonly lessonRepository: Repository<Lesson>,
    @InjectRepository(Exercise)
    private readonly exerciseRepository: Repository<Exercise>,
  ) {}

  getHello(): string {
    return 'Zaban API — English for Iranian Graduate Entrance Exams';
  }

  async onModuleInit(): Promise<void> {
    await this.ensureAdminUser();
    await this.seedIfEmpty();
    await this.patchCheckpointLessonKind();
    await this.patchListeningAudioUrls();
    await this.ensureDiagnosticLesson();
  }

  /** Idempotent: ensure default admin account exists. */
  private async ensureAdminUser(): Promise<void> {
    const email = 'admin@zaban.local';
    let admin = await this.userRepository.findOne({ where: { email } });
    const passwordHash = await bcrypt.hash('Admin1234!', 10);

    if (!admin) {
      admin = this.userRepository.create({
        email,
        passwordHash,
        refreshTokenHash: null,
        role: UserRole.ADMIN,
        banned: false,
      });
      await this.userRepository.save(admin);
      this.logger.log(`Admin user created: ${email}`);
      return;
    }

    if (admin.role !== UserRole.ADMIN) {
      admin.role = UserRole.ADMIN;
      await this.userRepository.save(admin);
      this.logger.log(`Admin role restored for ${email}`);
    }
  }

  /** Idempotent: mark unit-1 quiz as checkpoint for existing DBs. */
  private async patchCheckpointLessonKind(): Promise<void> {
    await this.lessonRepository.update(
      { title: 'آزمون ماژولار یونیت ۱' },
      { lessonKind: LessonKind.CHECKPOINT },
    );
  }

  /** Idempotent: attach static audio URLs to listening exercises. */
  private async patchListeningAudioUrls(): Promise<void> {
    const listening = await this.exerciseRepository.find({
      where: { type: QuestionType.LISTENING },
    });
    for (const ex of listening) {
      const content = { ...(ex.content as Record<string, unknown>) };
      if (content.audioUrl === '/audio/abandon.wav') continue;
      content.audioUrl = '/audio/abandon.wav';
      content.slowAudioUrl = '/audio/abandon-slow.wav';
      ex.content = content;
      await this.exerciseRepository.save(ex);
    }
  }

  /** Idempotent: ensure unit 1 has a diagnostic re-entry lesson. */
  private async ensureDiagnosticLesson(): Promise<void> {
    const existing = await this.lessonRepository.findOne({
      where: { lessonKind: LessonKind.DIAGNOSTIC },
    });
    if (existing) return;

    const unit = await this.unitRepository.findOne({
      where: { title: 'یونیت ۱ — واژگان پرتکرار' },
      relations: { words: true },
    });
    if (!unit) return;

    const words = unit.words ?? [];
    const diagnosticLesson = await this.lessonRepository.save(
      this.lessonRepository.create({
        title: 'آزمون بازگشت',
        summary: 'بعد از چند روز غیبت، سطح فعلی را می‌سنجد',
        order: 0,
        estimatedMinutes: 3,
        lessonKind: LessonKind.DIAGNOSTIC,
        unitId: unit.id,
      }),
    );

    const pick = (idx: number) => words[idx]?.id ?? null;
    await this.exerciseRepository.save([
      this.exerciseRepository.create({
        lessonId: diagnosticLesson.id,
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'معنی abandon؟',
        order: 1,
        wordId: pick(0),
        content: {
          stem: 'abandon',
          options: ['رها کردن', 'انباشتن', 'مبهم', 'کاهش'],
        },
        answer: { correctOption: 'رها کردن' },
      }),
      this.exerciseRepository.create({
        lessonId: diagnosticLesson.id,
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'معنی accumulate؟',
        order: 2,
        wordId: pick(1),
        content: {
          stem: 'accumulate',
          options: ['انباشتن', 'رها کردن', 'خیرخواه', 'مصادف'],
        },
        answer: { correctOption: 'انباشتن' },
      }),
      this.exerciseRepository.create({
        lessonId: diagnosticLesson.id,
        type: QuestionType.LISTENING,
        prompt: 'بعد از شنیدن، گزینه درست را انتخاب کنید.',
        order: 3,
        wordId: pick(0),
        content: {
          audioUrl: '/audio/abandon.wav',
          slowAudioUrl: '/audio/abandon-slow.wav',
          hint: 'مترادف leave',
          options: ['abandon', 'accumulate', 'coincide', 'diminish'],
        },
        answer: { correctOption: 'abandon' },
      }),
    ]);

    this.logger.log(`Diagnostic lesson ensured: ${diagnosticLesson.id}`);
  }

  private async seedIfEmpty(): Promise<void> {
    const courseCount = await this.courseRepository.count();
    if (courseCount > 0) {
      this.logger.log('Database already has courses — skipping seed.');
      return;
    }

    this.logger.log('Empty curriculum — seeding Course hierarchy...');

    const course = await this.courseRepository.save(
      this.courseRepository.create({
        title: 'واژگان عمومی کنکور ارشد',
        description: 'دوره نمونه فاز ۲ — ساختار دامنه-آزاد برای واژگان انگلیسی',
        domain: 'language',
        locale: 'fa',
        order: 1,
        isPublished: true,
      }),
    );

    const section = await this.sectionRepository.save(
      this.sectionRepository.create({
        title: 'سرفصل ۱ — واژگان پرتکرار',
        order: 1,
        courseId: course.id,
      }),
    );

    const unit = await this.unitRepository.save(
      this.unitRepository.create({
        title: 'یونیت ۱ — واژگان پرتکرار',
        order: 1,
        sectionId: section.id,
      }),
    );

    // Extra units for path UI (+ review-bank lesson on unit 2 for SRS inject)
    const [unit2] = await this.unitRepository.save([
      this.unitRepository.create({
        title: 'یونیت ۲ — مترادف‌های آکادمیک',
        order: 2,
        sectionId: section.id,
      }),
      this.unitRepository.create({
        title: 'یونیت ۳ — بافت جمله',
        order: 3,
        sectionId: section.id,
      }),
    ]);

    const words = await this.wordRepository.save([
      this.wordRepository.create({
        word: 'abandon',
        persianMeaning: 'رها کردن، ترک کردن',
        synonyms: ['desert', 'forsake', 'relinquish'],
        examples: [
          {
            english: 'They had to abandon the project due to lack of funding.',
            persian: 'آن‌ها مجبور شدند به دلیل کمبود بودجه پروژه را رها کنند.',
          },
        ],
        unitId: unit.id,
        courseId: course.id,
      }),
      this.wordRepository.create({
        word: 'accumulate',
        persianMeaning: 'انباشتن، جمع کردن',
        synonyms: ['amass', 'gather', 'collect'],
        examples: [
          {
            english: 'Dust began to accumulate on the unused bookshelves.',
            persian: 'گرد و غبار روی قفسه‌های بلااستفاده کتاب جمع شد.',
          },
        ],
        unitId: unit.id,
        courseId: course.id,
      }),
      this.wordRepository.create({
        word: 'ambiguous',
        persianMeaning: 'مبهم، دوپهلو',
        synonyms: ['vague', 'unclear', 'equivocal'],
        examples: [
          {
            english: 'His ambiguous reply left everyone confused.',
            persian: 'پاسخ مبهم او همه را گیج کرد.',
          },
        ],
        unitId: unit.id,
        courseId: course.id,
      }),
      this.wordRepository.create({
        word: 'benevolent',
        persianMeaning: 'خیرخواه، نیکوکار',
        synonyms: ['kind', 'charitable', 'generous'],
        examples: [
          {
            english: 'A benevolent donor funded the new library wing.',
            persian: 'یک اهداکننده خیرخواه بال جدید کتابخانه را تأمین مالی کرد.',
          },
        ],
        unitId: unit.id,
        courseId: course.id,
      }),
      this.wordRepository.create({
        word: 'coincide',
        persianMeaning: 'مصادف شدن، هم‌زمان بودن',
        synonyms: ['correspond', 'concur', 'overlap'],
        examples: [
          {
            english: 'The meeting coincided with her flight departure.',
            persian: 'جلسه با زمان پرواز او مصادف شد.',
          },
        ],
        unitId: unit.id,
        courseId: course.id,
      }),
      this.wordRepository.create({
        word: 'diminish',
        persianMeaning: 'کاهش یافتن، کم شدن',
        synonyms: ['decrease', 'lessen', 'reduce'],
        examples: [
          {
            english: 'Public interest in the topic began to diminish.',
            persian: 'علاقه عمومی به این موضوع رو به کاهش گذاشت.',
          },
        ],
        unitId: unit.id,
        courseId: course.id,
      }),
    ]);

    const diagnosticLesson = await this.lessonRepository.save(
      this.lessonRepository.create({
        title: 'آزمون بازگشت',
        summary: 'بعد از چند روز غیبت، سطح فعلی را می‌سنجد',
        order: 0,
        estimatedMinutes: 3,
        lessonKind: LessonKind.DIAGNOSTIC,
        unitId: unit.id,
      }),
    );

    const studyLesson = await this.lessonRepository.save(
      this.lessonRepository.create({
        title: 'آشنایی با ۶ واژه',
        summary: 'مرور معنی، مترادف و مثال',
        order: 1,
        estimatedMinutes: 4,
        unitId: unit.id,
      }),
    );

    const quizLesson = await this.lessonRepository.save(
      this.lessonRepository.create({
        title: 'آزمون ماژولار یونیت ۱',
        summary: 'پوشش همه انواع تمرین فاز ۵ — checkpoint یونیت ۱',
        order: 2,
        estimatedMinutes: 8,
        lessonKind: LessonKind.CHECKPOINT,
        unitId: unit.id,
      }),
    );

    await this.exerciseRepository.save([
      this.exerciseRepository.create({
        lessonId: diagnosticLesson.id,
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'معنی abandon؟',
        order: 1,
        wordId: words[0].id,
        content: {
          stem: 'abandon',
          options: ['رها کردن', 'انباشتن', 'مبهم', 'کاهش'],
        },
        answer: { correctOption: 'رها کردن' },
      }),
      this.exerciseRepository.create({
        lessonId: diagnosticLesson.id,
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'معنی accumulate؟',
        order: 2,
        wordId: words[1].id,
        content: {
          stem: 'accumulate',
          options: ['انباشتن', 'رها کردن', 'خیرخواه', 'مصادف'],
        },
        answer: { correctOption: 'انباشتن' },
      }),
      this.exerciseRepository.create({
        lessonId: diagnosticLesson.id,
        type: QuestionType.LISTENING,
        prompt: 'بعد از شنیدن، گزینه درست را انتخاب کنید.',
        order: 3,
        wordId: words[0].id,
        content: {
          audioUrl: '/audio/abandon.wav',
          slowAudioUrl: '/audio/abandon-slow.wav',
          hint: 'مترادف leave',
          options: ['abandon', 'accumulate', 'coincide', 'diminish'],
        },
        answer: { correctOption: 'abandon' },
      }),
      this.exerciseRepository.create({
        lessonId: quizLesson.id,
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'معنی واژه «abandon» کدام است؟',
        order: 1,
        wordId: words[0].id,
        content: {
          stem: 'abandon',
          options: ['انباشتن', 'رها کردن', 'مبهم بودن', 'کاهش یافتن'],
        },
        answer: { correctOption: 'رها کردن' },
      }),
      this.exerciseRepository.create({
        lessonId: quizLesson.id,
        type: QuestionType.MATCHING,
        difficulty: QuestionDifficulty.EASY,
        prompt: 'هر واژه انگلیسی را به معنی فارسی درست وصل کنید.',
        order: 2,
        wordId: words[0].id,
        content: {
          leftItems: [
            words[0].word,
            words[1].word,
            words[2].word,
            words[3].word,
          ],
          rightItems: ['خیرخواه', 'رها کردن', 'مبهم', 'انباشتن'],
        },
        answer: {
          pairs: {
            abandon: 'رها کردن',
            accumulate: 'انباشتن',
            ambiguous: 'مبهم',
            benevolent: 'خیرخواه',
          },
        },
      }),
      this.exerciseRepository.create({
        lessonId: quizLesson.id,
        type: QuestionType.CLOZE_TYPING,
        difficulty: QuestionDifficulty.EASY,
        prompt: 'جای خالی را با واژه مناسب پر کنید.',
        order: 3,
        wordId: words[5].id,
        content: {
          text: 'Public interest in the topic began to _____.',
          blanks: [{ id: 'blank_1', position: 0 }],
        },
        answer: { blanks: { blank_1: 'diminish' } },
      }),
      this.exerciseRepository.create({
        lessonId: quizLesson.id,
        type: QuestionType.WORD_BANK,
        prompt: 'با کلمات بانک، جمله درست را بسازید.',
        order: 4,
        wordId: words[0].id,
        content: {
          instruction: 'Tap words in order',
          bank: ['They', 'had', 'to', 'abandon', 'the', 'project'],
        },
        answer: {
          order: ['They', 'had', 'to', 'abandon', 'the', 'project'],
        },
      }),
      this.exerciseRepository.create({
        lessonId: quizLesson.id,
        type: QuestionType.TRANSLATION,
        prompt: 'ترجمه کنید.',
        order: 5,
        wordId: words[3].id,
        content: {
          direction: 'en_to_fa',
          source: 'benevolent',
        },
        answer: {
          texts: ['خیرخواه', 'نیکوکار', 'خیرخواه، نیکوکار'],
        },
      }),
      this.exerciseRepository.create({
        lessonId: quizLesson.id,
        type: QuestionType.REORDER,
        prompt: 'ترتیب حروف واژه ambiguous را درست کنید.',
        order: 6,
        wordId: words[2].id,
        content: {
          items: ['b', 'i', 'g', 'u', 'o', 'a', 'm', 'u', 's'],
        },
        answer: { order: ['a', 'm', 'b', 'i', 'g', 'u', 'o', 'u', 's'] },
      }),
      this.exerciseRepository.create({
        lessonId: quizLesson.id,
        type: QuestionType.LISTENING,
        prompt: 'بعد از شنیدن، گزینه درست را انتخاب کنید.',
        order: 7,
        wordId: words[0].id,
        content: {
          audioUrl: '/audio/abandon.wav',
          slowAudioUrl: '/audio/abandon-slow.wav',
          hint: 'مترادف leave',
          options: ['abandon', 'accumulate', 'coincide', 'diminish'],
        },
        answer: { correctOption: 'abandon' },
      }),
      this.exerciseRepository.create({
        lessonId: quizLesson.id,
        type: QuestionType.SPEAKING,
        prompt: 'این واژه را بگویید (فعلاً تایپ موقت).',
        order: 8,
        wordId: words[1].id,
        content: {
          prompt: 'Pronounce the word',
          targetText: 'accumulate',
        },
        answer: { text: 'accumulate' },
      }),
      this.exerciseRepository.create({
        lessonId: quizLesson.id,
        type: QuestionType.IMAGE_WORD,
        prompt: 'تصویر با کدام واژه جور است؟',
        order: 9,
        wordId: words[3].id,
        content: {
          imageUrl: null,
          imageLabel: '[تصویر: کتابخانه / اهدا]',
          options: ['benevolent', 'ambiguous', 'coincide', 'diminish'],
        },
        answer: { correctOption: 'benevolent' },
      }),
    ]);

    const reviewLesson = await this.lessonRepository.save(
      this.lessonRepository.create({
        title: 'بانک مرور SRS',
        summary: 'تمرین‌های کمکی برای تزریق مرور به درس‌های دیگر',
        order: 1,
        estimatedMinutes: 5,
        unitId: unit2.id,
      }),
    );

    await this.exerciseRepository.save([
      this.exerciseRepository.create({
        lessonId: reviewLesson.id,
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'مرور: abandon یعنی؟',
        order: 1,
        wordId: words[0].id,
        content: {
          stem: 'abandon',
          options: ['رها کردن', 'انباشتن', 'مصادف شدن', 'کاهش یافتن'],
        },
        answer: { correctOption: 'رها کردن' },
      }),
      this.exerciseRepository.create({
        lessonId: reviewLesson.id,
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'مرور: diminish یعنی؟',
        order: 2,
        wordId: words[5].id,
        content: {
          stem: 'diminish',
          options: ['کاهش یافتن', 'خیرخواه', 'مبهم', 'رها کردن'],
        },
        answer: { correctOption: 'کاهش یافتن' },
      }),
      this.exerciseRepository.create({
        lessonId: reviewLesson.id,
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'مرور: ambiguous یعنی؟',
        order: 3,
        wordId: words[2].id,
        content: {
          stem: 'ambiguous',
          options: ['مبهم', 'انباشتن', 'خیرخواه', 'مصادف شدن'],
        },
        answer: { correctOption: 'مبهم' },
      }),
    ]);

    this.logger.log(
      `Seed complete: course=${course.id}, unit=${unit.id}, diagnosticLesson=${diagnosticLesson.id}, studyLesson=${studyLesson.id}, quizLesson=${quizLesson.id}, reviewLesson=${reviewLesson.id}, words=${words.length}, exercises=15`,
    );
  }

  private async seedPlacementQuestionsIfNeeded(): Promise<void> {
    const placementCount = await this.questionRepository.count({
      where: {
        difficulty: In([
          QuestionDifficulty.STANDARD,
          QuestionDifficulty.HARD,
        ]),
        type: QuestionType.MULTIPLE_CHOICE,
      },
    });

    if (placementCount >= 10) {
      return;
    }

    this.logger.log('Seeding placement test questions...');

    let section = await this.sectionRepository.findOne({
      where: { order: 1 },
    });

    if (!section) {
      section = await this.sectionRepository.save(
        this.sectionRepository.create({
          title: 'واژگان عمومی کنکور ارشد',
          order: 1,
        }),
      );
    }

    const placementUnit = await this.unitRepository.save(
      this.unitRepository.create({
        title: 'آزمون تعیین سطح — واژگان کنکور',
        order: 99,
        sectionId: section.id,
      }),
    );

    const placementQuestions: Array<{
      prompt: string;
      stem: string;
      options: string[];
      correct: string;
      difficulty: QuestionDifficulty;
    }> = [
      {
        prompt: 'معنی واژه «meticulous» کدام است؟',
        stem: 'meticulous',
        options: ['سست', 'دقیق و جزئی‌نگر', 'بی‌تفاوت', 'ناگهانی'],
        correct: 'دقیق و جزئی‌نگر',
        difficulty: QuestionDifficulty.STANDARD,
      },
      {
        prompt: 'معنی واژه «ubiquitous» کدام است؟',
        stem: 'ubiquitous',
        options: ['کمیاب', 'همه‌جا حاضر', 'مبهم', 'موقت'],
        correct: 'همه‌جا حاضر',
        difficulty: QuestionDifficulty.HARD,
      },
      {
        prompt: 'معنی واژه «alleviate» کدام است؟',
        stem: 'alleviate',
        options: ['تشدید کردن', 'تسکین دادن', 'نادیده گرفتن', 'تحمیل کردن'],
        correct: 'تسکین دادن',
        difficulty: QuestionDifficulty.STANDARD,
      },
      {
        prompt: 'معنی واژه «pragmatic» کدام است؟',
        stem: 'pragmatic',
        options: ['آرمانی‌گرا', 'عمل‌گرا', 'بی‌هدف', 'احساسی'],
        correct: 'عمل‌گرا',
        difficulty: QuestionDifficulty.STANDARD,
      },
      {
        prompt: 'معنی واژه «scrutinize» کدام است؟',
        stem: 'scrutinize',
        options: ['رد کردن', 'با دقت بررسی کردن', 'تأیید سریع', 'فراموش کردن'],
        correct: 'با دقت بررسی کردن',
        difficulty: QuestionDifficulty.HARD,
      },
      {
        prompt: 'معنی واژه «coherent» کدام است؟',
        stem: 'coherent',
        options: ['مبهم', 'منسجم', 'پراکنده', 'بی‌ربط'],
        correct: 'منسجم',
        difficulty: QuestionDifficulty.STANDARD,
      },
      {
        prompt: 'معنی واژه «detrimental» کدام است؟',
        stem: 'detrimental',
        options: ['مفید', 'مضر', 'خنثی', 'ضروری'],
        correct: 'مضر',
        difficulty: QuestionDifficulty.STANDARD,
      },
      {
        prompt: 'معنی واژه «ephemeral» کدام است؟',
        stem: 'ephemeral',
        options: ['پایدار', 'زودگذر', 'ابدی', 'قدیمی'],
        correct: 'زودگذر',
        difficulty: QuestionDifficulty.HARD,
      },
      {
        prompt: 'معنی واژه «indigenous» کدام است؟',
        stem: 'indigenous',
        options: ['وارداتی', 'بومی', 'خارجی', 'مصنوعی'],
        correct: 'بومی',
        difficulty: QuestionDifficulty.STANDARD,
      },
      {
        prompt: 'معنی واژه «reluctant» کدام است؟',
        stem: 'reluctant',
        options: ['مشتاق', 'بی‌میل', 'مصمم', 'خوشحال'],
        correct: 'بی‌میل',
        difficulty: QuestionDifficulty.STANDARD,
      },
      {
        prompt: 'معنی واژه «substantiate» کدام است؟',
        stem: 'substantiate',
        options: ['رد کردن', 'سندیت بخشیدن', 'نادیده گرفتن', 'تقلیل دادن'],
        correct: 'سندیت بخشیدن',
        difficulty: QuestionDifficulty.HARD,
      },
      {
        prompt: 'معنی واژه «versatile» کدام است؟',
        stem: 'versatile',
        options: ['تک‌بعدی', 'چندکاره', 'ثابت', 'ضعیف'],
        correct: 'چندکاره',
        difficulty: QuestionDifficulty.STANDARD,
      },
    ];

    await this.questionRepository.save(
      placementQuestions.map((item) =>
        this.questionRepository.create({
          unitId: placementUnit.id,
          type: QuestionType.MULTIPLE_CHOICE,
          difficulty: item.difficulty,
          prompt: item.prompt,
          content: {
            stem: item.stem,
            options: item.options,
          },
          answer: {
            correctOption: item.correct,
          },
        }),
      ),
    );

    this.logger.log(
      `Placement seed complete: ${placementQuestions.length} questions added.`,
    );
  }
}

import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Section } from './sections/entities/section.entity';
import { Unit } from './units/entities/unit.entity';
import { Word } from './words/entities/word.entity';
import { Question } from './questions/entities/question.entity';
import { QuestionType } from './questions/types/question.types';

@Injectable()
export class AppService implements OnModuleInit {
  private readonly logger = new Logger(AppService.name);

  constructor(
    @InjectRepository(Section)
    private readonly sectionRepository: Repository<Section>,
    @InjectRepository(Unit)
    private readonly unitRepository: Repository<Unit>,
    @InjectRepository(Word)
    private readonly wordRepository: Repository<Word>,
    @InjectRepository(Question)
    private readonly questionRepository: Repository<Question>,
  ) {}

  getHello(): string {
    return 'Zaban API — English for Iranian Graduate Entrance Exams';
  }

  async onModuleInit(): Promise<void> {
    await this.seedIfEmpty();
  }

  private async seedIfEmpty(): Promise<void> {
    const sectionCount = await this.sectionRepository.count();
    if (sectionCount > 0) {
      this.logger.log('Database already has data — skipping seed.');
      return;
    }

    this.logger.log('Empty database detected — seeding sample data...');

    const section = await this.sectionRepository.save(
      this.sectionRepository.create({
        title: 'واژگان عمومی کنکور ارشد',
        order: 1,
      }),
    );

    const unit = await this.unitRepository.save(
      this.unitRepository.create({
        title: 'یونیت ۱ — واژگان پرتکرار',
        order: 1,
        sectionId: section.id,
      }),
    );

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
      }),
    ]);

    await this.questionRepository.save([
      // 1) Multiple choice
      this.questionRepository.create({
        unitId: unit.id,
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'معنی واژه «abandon» کدام است؟',
        content: {
          stem: 'abandon',
          options: [
            'انباشتن',
            'رها کردن',
            'مبهم بودن',
            'کاهش یافتن',
          ],
        },
        answer: {
          correctOption: 'رها کردن',
        },
      }),
      // 2) Matching
      this.questionRepository.create({
        unitId: unit.id,
        type: QuestionType.MATCHING,
        prompt: 'هر واژه انگلیسی را به معنی فارسی درست وصل کنید.',
        content: {
          leftItems: [
            words[0].word,
            words[1].word,
            words[2].word,
            words[3].word,
          ],
          rightItems: [
            'خیرخواه',
            'رها کردن',
            'مبهم',
            'انباشتن',
          ],
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
      // 3) Cloze typing
      this.questionRepository.create({
        unitId: unit.id,
        type: QuestionType.CLOZE_TYPING,
        prompt: 'جای خالی را با واژه مناسب پر کنید.',
        content: {
          text: 'Public interest in the topic began to _____.',
          blanks: [{ id: 'blank_1', position: 0 }],
        },
        answer: {
          blanks: {
            blank_1: 'diminish',
          },
        },
      }),
    ]);

    this.logger.log(
      `Seed complete: 1 section, 1 unit, ${words.length} words, 3 questions.`,
    );
  }
}

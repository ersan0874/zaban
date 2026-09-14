import 'package:zaban/models/path_node_model.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/models/word_model.dart';

/// Legacy offline fixtures kept for reference / offline demos.
/// Main app path (Phase 4+) loads from the NestJS API instead.
class SampleData {
  static const unitTitle = 'یونیت ۱ — واژگان پرتکرار';

  static const pathNodes = <PathNodeModel>[
    PathNodeModel(
      id: 'unit-1',
      title: unitTitle,
      subtitle: '۶ واژه · ۳ سوال',
      order: 1,
      status: PathNodeStatus.active,
    ),
    PathNodeModel(
      id: 'unit-2',
      title: 'یونیت ۲ — مترادف‌های آکادمیک',
      subtitle: 'قفل',
      order: 2,
      status: PathNodeStatus.locked,
    ),
    PathNodeModel(
      id: 'unit-3',
      title: 'یونیت ۳ — بافت جمله',
      subtitle: 'قفل',
      order: 3,
      status: PathNodeStatus.locked,
    ),
    PathNodeModel(
      id: 'unit-4',
      title: 'یونیت ۴ — مرور ترکیبی',
      subtitle: 'قفل',
      order: 4,
      status: PathNodeStatus.locked,
    ),
    PathNodeModel(
      id: 'unit-5',
      title: 'یونیت ۵ — آزمون بخش',
      subtitle: 'قفل',
      order: 5,
      status: PathNodeStatus.locked,
    ),
    PathNodeModel(
      id: 'unit-6',
      title: 'یونیت ۶ — چالش نهایی',
      subtitle: 'قفل',
      order: 6,
      status: PathNodeStatus.locked,
    ),
  ];

  static const words = <WordModel>[
    WordModel(
      id: 'w1',
      word: 'abandon',
      persianMeaning: 'رها کردن، ترک کردن',
      synonyms: ['desert', 'forsake', 'relinquish'],
      examples: [
        WordExample(
          english: 'They had to abandon the project due to lack of funding.',
          persian: 'آن‌ها مجبور شدند به دلیل کمبود بودجه پروژه را رها کنند.',
        ),
      ],
    ),
    WordModel(
      id: 'w2',
      word: 'accumulate',
      persianMeaning: 'انباشتن، جمع کردن',
      synonyms: ['amass', 'gather', 'collect'],
      examples: [
        WordExample(
          english: 'Dust began to accumulate on the unused bookshelves.',
          persian: 'گرد و غبار روی قفسه‌های بلااستفاده کتاب جمع شد.',
        ),
      ],
    ),
    WordModel(
      id: 'w3',
      word: 'ambiguous',
      persianMeaning: 'مبهم، دوپهلو',
      synonyms: ['vague', 'unclear', 'equivocal'],
      examples: [
        WordExample(
          english: 'His ambiguous reply left everyone confused.',
          persian: 'پاسخ مبهم او همه را گیج کرد.',
        ),
      ],
    ),
    WordModel(
      id: 'w4',
      word: 'benevolent',
      persianMeaning: 'خیرخواه، نیکوکار',
      synonyms: ['kind', 'charitable', 'generous'],
      examples: [
        WordExample(
          english: 'A benevolent donor funded the new library wing.',
          persian: 'یک اهداکننده خیرخواه بال جدید کتابخانه را تأمین مالی کرد.',
        ),
      ],
    ),
    WordModel(
      id: 'w5',
      word: 'coincide',
      persianMeaning: 'مصادف شدن، هم‌زمان بودن',
      synonyms: ['correspond', 'concur', 'overlap'],
      examples: [
        WordExample(
          english: 'The meeting coincided with her flight departure.',
          persian: 'جلسه با زمان پرواز او مصادف شد.',
        ),
      ],
    ),
    WordModel(
      id: 'w6',
      word: 'diminish',
      persianMeaning: 'کاهش یافتن، کم شدن',
      synonyms: ['decrease', 'lessen', 'reduce'],
      examples: [
        WordExample(
          english: 'Public interest in the topic began to diminish.',
          persian: 'علاقه عمومی به این موضوع رو به کاهش گذاشت.',
        ),
      ],
    ),
  ];

  static const questions = <QuestionModel>[
    QuestionModel(
      id: 'q1',
      type: 'multiple_choice',
      prompt: 'معنی واژه «abandon» کدام است؟',
      content: {
        'stem': 'abandon',
        'options': ['انباشتن', 'رها کردن', 'مبهم بودن', 'کاهش یافتن'],
      },
      answer: {'correctOption': 'رها کردن'},
    ),
    QuestionModel(
      id: 'q2',
      type: 'matching',
      prompt: 'هر واژه انگلیسی را به معنی فارسی درست وصل کنید.',
      content: {
        'leftItems': ['abandon', 'accumulate', 'ambiguous', 'benevolent'],
        'rightItems': ['خیرخواه', 'رها کردن', 'مبهم', 'انباشتن'],
      },
      answer: {
        'pairs': {
          'abandon': 'رها کردن',
          'accumulate': 'انباشتن',
          'ambiguous': 'مبهم',
          'benevolent': 'خیرخواه',
        },
      },
    ),
    QuestionModel(
      id: 'q3',
      type: 'cloze_typing',
      prompt: 'جای خالی را با واژه مناسب پر کنید.',
      content: {
        'text': 'Public interest in the topic began to _____.',
        'blanks': [
          {'id': 'blank_1', 'position': 0},
        ],
      },
      answer: {
        'blanks': {'blank_1': 'diminish'},
      },
    ),
  ];
}

import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { Section } from './sections/entities/section.entity';
import { Unit } from './units/entities/unit.entity';
import { Word } from './words/entities/word.entity';
import { Question } from './questions/entities/question.entity';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const mockRepository = {
      count: jest.fn().mockResolvedValue(1),
      save: jest.fn(),
      create: jest.fn(),
    };

    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        { provide: getRepositoryToken(Section), useValue: mockRepository },
        { provide: getRepositoryToken(Unit), useValue: mockRepository },
        { provide: getRepositoryToken(Word), useValue: mockRepository },
        { provide: getRepositoryToken(Question), useValue: mockRepository },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return API greeting', () => {
      expect(appController.getHello()).toContain('Zaban API');
    });
  });
});

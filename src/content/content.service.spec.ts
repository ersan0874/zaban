import { plainToInstance } from 'class-transformer';
import { ContentService } from './content.service';
import { UpdateDraftExerciseDto } from './dto/update-draft.dto';
import { DraftQuality } from './entities/content-draft-exercise.entity';

describe('ContentService.updateExercise', () => {
  function serviceWith(exercise: Record<string, unknown>) {
    const exerciseRepository = {
      findOneBy: jest.fn().mockResolvedValue(exercise),
      save: jest.fn((e: unknown) => Promise.resolve(e)),
    };
    const service = new ContentService(
      {} as never,
      {} as never,
      {} as never,
      {} as never,
      exerciseRepository as never,
      {} as never,
      {} as never,
      {} as never,
      {} as never,
    );
    return { service, exerciseRepository };
  }

  it('keeps content and answer when only the prompt is sent', async () => {
    const exercise = {
      id: 'e1',
      type: 'multiple_choice',
      prompt: 'old',
      content: { stem: 'Which?', options: ['a', 'b'] },
      answer: { correctOption: 'a' },
      quality: DraftQuality.NEEDS_REVIEW,
      qualityNote: 'check',
    };
    const { service } = serviceWith(exercise);
    const dto = plainToInstance(UpdateDraftExerciseDto, { prompt: 'new' });

    const saved = await service.updateExercise('e1', dto);

    expect(saved.prompt).toBe('new');
    expect(saved.content).toEqual({ stem: 'Which?', options: ['a', 'b'] });
    expect(saved.answer).toEqual({ correctOption: 'a' });
    expect(saved.quality).toBe(DraftQuality.OK);
  });
});

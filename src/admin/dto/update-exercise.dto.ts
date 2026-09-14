import { PartialType, OmitType } from '@nestjs/swagger';
import { CreateExerciseDto } from './create-exercise.dto';

export class UpdateExerciseDto extends PartialType(
  OmitType(CreateExerciseDto, ['lessonId'] as const),
) {}

import {
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

export class CreateExerciseDto {
  @IsUUID()
  lessonId: string;

  @IsString()
  type: string;

  @IsString()
  prompt: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  order?: number;

  @IsObject()
  content: Record<string, unknown>;

  @IsObject()
  answer: Record<string, unknown>;

  @IsOptional()
  @IsUUID()
  wordId?: string;
}

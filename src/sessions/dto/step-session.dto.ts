import { ApiPropertyOptional } from '@nestjs/swagger';
import { Allow, IsOptional, IsString, IsUUID, Matches } from 'class-validator';

/**
 * One page passed in a lesson: a question (exerciseId + response) or a
 * lesson-note page (key `note:<index>`). Each step burns energy once.
 */
export class StepSessionDto {
  @ApiPropertyOptional({
    description: 'Question page: the exercise being answered',
  })
  @IsOptional()
  @IsUUID()
  exerciseId?: string;

  @ApiPropertyOptional({
    description: 'Client answer payload shaped by exercise type',
  })
  @IsOptional()
  @Allow()
  response?: unknown;

  @ApiPropertyOptional({
    description: 'Non-question page, e.g. `note:0` for the first lesson note',
    example: 'note:0',
  })
  @IsOptional()
  @IsString()
  @Matches(/^note:\d{1,3}$/)
  page?: string;
}

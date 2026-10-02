import { ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsOptional, IsUUID } from 'class-validator';

export class MarkLateGradesDto {
  @ApiPropertyOptional({
    type: [String],
    description: 'Attempt ids to mark seen; omit to mark all',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(100)
  @IsUUID(undefined, { each: true })
  attemptIds?: string[];
}

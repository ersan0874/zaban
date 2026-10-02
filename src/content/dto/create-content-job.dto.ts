import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

/** Multipart form fields sent next to the uploaded `files`. */
export class CreateContentJobDto {
  @ApiProperty({ example: 'واژگان کنکور ارشد — جلد ۱' })
  @IsString()
  @MinLength(2)
  @MaxLength(255)
  title: string;

  @ApiPropertyOptional({
    example: 'fa',
    description: 'Language of notes and instructions',
  })
  @IsOptional()
  @IsString()
  @MaxLength(32)
  outputLanguage?: string;

  @ApiPropertyOptional({
    description: 'JSON object: question type → count per lesson',
    example: '{"multiple_choice":3,"cloze_typing":2,"essay":1}',
  })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (typeof value !== 'string') return value;
    try {
      return JSON.parse(value) as unknown;
    } catch {
      return value;
    }
  })
  @IsObject()
  questionCounts?: Record<string, number>;

  @ApiPropertyOptional({
    description: 'Extra guidance for the AI (audience, level, focus)',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  instructions?: string;
}

import { IsInt, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class CreateLessonDto {
  @IsUUID()
  unitId: string;

  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  summary?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  order?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  estimatedMinutes?: number;
}

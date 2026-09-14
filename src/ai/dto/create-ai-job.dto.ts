import { IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateAiJobDto {
  @IsString()
  sourceText: string;

  @IsOptional()
  @IsUUID()
  createdBy?: string;
}

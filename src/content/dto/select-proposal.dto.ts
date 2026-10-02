import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsObject, IsOptional } from 'class-validator';
import type { CourseOutline } from '../entities/content-proposal.entity';

export class SelectProposalDto {
  @ApiPropertyOptional({
    description: 'Edited outline; omit to use the proposal as generated',
  })
  @IsOptional()
  @IsObject()
  outline?: CourseOutline;
}

import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsNotEmpty,
  IsString,
  IsUUID,
  ValidateNested,
} from 'class-validator';

export class PlacementAnswerDto {
  @ApiProperty({ example: 'uuid-of-question' })
  @IsUUID()
  questionId: string;

  @ApiProperty({
    example: 'رها کردن',
    description: 'User answer payload (option text for multiple choice)',
  })
  @IsNotEmpty()
  answer: string | Record<string, unknown>;
}

export class SubmitPlacementDto {
  @ApiProperty({ type: [PlacementAnswerDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => PlacementAnswerDto)
  answers: PlacementAnswerDto[];
}

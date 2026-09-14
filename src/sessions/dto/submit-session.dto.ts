import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  Allow,
  ArrayMinSize,
  IsArray,
  IsNotEmpty,
  IsUUID,
  ValidateNested,
} from 'class-validator';

export class ExerciseResponseDto {
  @ApiProperty()
  @IsUUID()
  exerciseId: string;

  @ApiProperty({
    description: 'Client answer payload shaped by exercise type',
  })
  @Allow()
  @IsNotEmpty()
  response: unknown;
}

export class SubmitSessionDto {
  @ApiProperty({ type: [ExerciseResponseDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ExerciseResponseDto)
  answers: ExerciseResponseDto[];
}

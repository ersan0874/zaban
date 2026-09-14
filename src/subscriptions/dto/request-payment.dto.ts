import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { PlanType } from '../entities/subscription.entity';

export class RequestPaymentDto {
  @ApiProperty({
    enum: PlanType,
    example: PlanType.MONTHLY,
  })
  @IsEnum(PlanType)
  planType: PlanType;
}

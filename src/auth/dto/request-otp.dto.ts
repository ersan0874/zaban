import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsOptional,
  IsString,
  Matches,
  ValidateIf,
} from 'class-validator';

export class RequestOtpDto {
  @ApiPropertyOptional({ example: 'user@example.com' })
  @ValidateIf((o: RequestOtpDto) => !o.phoneNumber)
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ example: '09123456789' })
  @ValidateIf((o: RequestOtpDto) => !o.email)
  @IsString()
  @Matches(/^09\d{9}$/, { message: 'phoneNumber must be a valid Iranian mobile number' })
  @IsOptional()
  phoneNumber?: string;
}

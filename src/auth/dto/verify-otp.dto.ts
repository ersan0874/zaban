import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsOptional,
  IsString,
  Length,
  Matches,
  ValidateIf,
} from 'class-validator';

export class VerifyOtpDto {
  @ApiPropertyOptional({ example: 'user@example.com' })
  @ValidateIf((o: VerifyOtpDto) => !o.phoneNumber)
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ example: '09123456789' })
  @ValidateIf((o: VerifyOtpDto) => !o.email)
  @IsString()
  @Matches(/^09\d{9}$/, { message: 'phoneNumber must be a valid Iranian mobile number' })
  @IsOptional()
  phoneNumber?: string;

  @ApiProperty({ example: '12345' })
  @IsString()
  @Length(4, 5)
  code: string;
}

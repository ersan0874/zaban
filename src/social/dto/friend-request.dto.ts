import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class FriendRequestDto {
  @ApiProperty({ description: 'Friend email or user UUID' })
  @IsString()
  @IsNotEmpty()
  emailOrUserId: string;
}

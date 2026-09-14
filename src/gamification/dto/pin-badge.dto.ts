import { IsBoolean } from 'class-validator';

export class PinBadgeDto {
  @IsBoolean()
  pinned: boolean;
}

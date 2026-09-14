import { IsEnum, IsString } from 'class-validator';
import { PurchasePlatform } from '../entities/purchase.entity';

export class VerifyPurchaseDto {
  @IsString()
  productId: string;

  @IsEnum(PurchasePlatform)
  platform: PurchasePlatform;

  @IsString()
  receipt: string;
}

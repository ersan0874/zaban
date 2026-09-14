import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { BillingService } from './billing.service';
import { VerifyPurchaseDto } from './dto/verify-purchase.dto';

@Controller('billing')
@UseGuards(JwtAuthGuard)
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  @Post('verify')
  verify(
    @CurrentUser() user: { id: string },
    @Body() dto: VerifyPurchaseDto,
  ) {
    return this.billingService.verifyPurchase(user.id, dto);
  }

  @Get('me')
  me(@CurrentUser() user: { id: string }) {
    return this.billingService.getBillingMe(user.id);
  }
}

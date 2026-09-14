import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import type { Response } from 'express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { User } from '../users/entities/user.entity';
import { RequestPaymentDto } from './dto/request-payment.dto';
import { PaymentsService } from './payments.service';

@ApiTags('payments')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('request')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Create a mock payment link for a Super plan' })
  @ApiResponse({ status: 200, description: 'Returns paymentUrl and authority' })
  requestPayment(
    @CurrentUser() user: User,
    @Body() dto: RequestPaymentDto,
  ) {
    return this.paymentsService.requestPayment(user.id, dto.planType);
  }

  @Get('verify')
  @ApiOperation({
    summary: 'Payment callback — activates subscription after successful payment',
  })
  @ApiQuery({ name: 'authority', required: true })
  @ApiQuery({ name: 'Status', required: false, example: 'OK' })
  @ApiResponse({ status: 200, description: 'Payment verified / subscription activated' })
  async verifyPayment(
    @Res() res: Response,
    @Query('authority') authority: string,
    @Query('Status') status?: string,
    @Query('status') statusLower?: string,
  ) {
    const result = await this.paymentsService.verifyPayment(
      authority,
      status ?? statusLower,
    );

    const title = result.success ? 'پرداخت موفق' : 'پرداخت ناموفق';
    const color = result.success ? '#059669' : '#DC2626';
    const detail = result.message ?? '';

    res.type('html').send(`<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title}</title>
  <style>
    body { font-family: Tahoma, sans-serif; background: #0B1F2A; color: #fff;
      display:flex; align-items:center; justify-content:center; min-height:100vh; margin:0; }
    .card { background: #132F3C; border-radius: 20px; padding: 32px; text-align:center;
      max-width: 420px; box-shadow: 0 20px 50px rgba(0,0,0,.35); }
    h1 { color: ${color}; margin-bottom: 12px; }
    p { color: #9DC4C0; line-height: 1.7; }
  </style>
</head>
<body>
  <div class="card">
    <h1>${title}</h1>
    <p>${detail}</p>
    <p>می‌توانید این صفحه را ببندید و به اپلیکیشن بازگردید.</p>
  </div>
</body>
</html>`);
  }
}

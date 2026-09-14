import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { EconomyService } from './economy.service';

@ApiTags('economy')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('economy')
export class EconomyController {
  constructor(private readonly economyService: EconomyService) {}

  @Get('wallet')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({ summary: 'Gem wallet balance' })
  getWallet(@CurrentUser() user: AuthUserPayload) {
    return this.economyService.getWallet(user.id);
  }

  @Get('shop')
  @ApiOperation({ summary: 'Active shop catalog' })
  listShop() {
    return this.economyService.listShopItems();
  }

  @Post('shop/:itemKey/buy')
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @ApiOperation({ summary: 'Purchase a shop item with gems' })
  buyItem(
    @CurrentUser() user: AuthUserPayload,
    @Param('itemKey') itemKey: string,
  ) {
    return this.economyService.purchaseShopItem(user.id, itemKey);
  }

  @Get('leagues/current')
  @ApiOperation({ summary: 'Current weekly league membership' })
  getCurrentLeague(@CurrentUser() user: AuthUserPayload) {
    return this.economyService.getCurrentLeague(user.id);
  }

  @Get('leagues/leaderboard')
  @ApiOperation({ summary: 'Top 50 in your current league week/tier' })
  getLeaderboard(@CurrentUser() user: AuthUserPayload) {
    return this.economyService.getLeaderboard(user.id);
  }
}

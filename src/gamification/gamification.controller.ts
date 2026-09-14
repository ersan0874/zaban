import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { GamificationService } from './gamification.service';
import { PinBadgeDto } from './dto/pin-badge.dto';

@ApiTags('gamification')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('gamification')
export class GamificationController {
  constructor(private readonly gamificationService: GamificationService) {}

  @Get()
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({ summary: 'Streak, XP, hearts, quests, badges, loot' })
  getSnapshot(@CurrentUser() user: AuthUserPayload) {
    return this.gamificationService.getSnapshot(user.id);
  }

  @Post('loot/:lootId/open')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiOperation({ summary: 'Open a loot box (server applies rewards)' })
  openLoot(
    @CurrentUser() user: AuthUserPayload,
    @Param('lootId') lootId: string,
  ) {
    return this.gamificationService.openLootBox(user.id, lootId);
  }

  @Patch('badges/:badgeKey/pin')
  @ApiOperation({ summary: 'Pin or unpin a badge on profile' })
  pinBadge(
    @CurrentUser() user: AuthUserPayload,
    @Param('badgeKey') badgeKey: string,
    @Body() body: PinBadgeDto,
  ) {
    return this.gamificationService.pinBadge(user.id, badgeKey, body.pinned);
  }
}

import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ProgressService } from './progress.service';

@ApiTags('progress')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class ProgressController {
  constructor(private readonly progressService: ProgressService) {}

  @Get('progress')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({ summary: 'User skill scores and SRS summary' })
  getProgress(@CurrentUser() user: AuthUserPayload) {
    return this.progressService.getProgressSummary(user.id);
  }

  @Get('reviews')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({ summary: 'Due review queue (forgetting curve)' })
  getReviews(
    @CurrentUser() user: AuthUserPayload,
    @Query('limit') limit?: string,
  ) {
    const parsed = limit ? Number(limit) : 50;
    return this.progressService.getDueReviews(
      user.id,
      Number.isFinite(parsed) ? Math.min(100, Math.max(1, parsed)) : 50,
    );
  }

  @Get('progress/:itemKind/:itemId')
  @ApiOperation({ summary: 'Single item progress' })
  getItem(
    @CurrentUser() user: AuthUserPayload,
    @Param('itemKind') itemKind: string,
    @Param('itemId') itemId: string,
  ) {
    return this.progressService.getItemProgress(user.id, itemKind, itemId);
  }
}

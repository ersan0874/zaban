import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { LateGradesService } from './late-grades.service';
import { MarkLateGradesDto } from './dto/mark-late-grades.dto';

@ApiTags('sessions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('me/late-grades')
export class LateGradesController {
  constructor(private readonly lateGrades: LateGradesService) {}

  @Get()
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({ summary: 'Essay answers graded after the lesson ended' })
  list(@CurrentUser() user: AuthUserPayload) {
    return this.lateGrades.listUnseen(user.id);
  }

  @Post('seen')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiOperation({ summary: 'Mark late-grade notices as seen' })
  async markSeen(
    @CurrentUser() user: AuthUserPayload,
    @Body() dto: MarkLateGradesDto,
  ) {
    return { marked: await this.lateGrades.markSeen(user.id, dto.attemptIds) };
  }
}

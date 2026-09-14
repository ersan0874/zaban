import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { SessionsService } from './sessions.service';
import { SubmitSessionDto } from './dto/submit-session.dto';

@ApiTags('sessions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class SessionsController {
  constructor(private readonly sessionsService: SessionsService) {}

  @Post('lessons/:lessonId/sessions')
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Start a temporary lesson session (exercises without answers)',
  })
  start(
    @CurrentUser() user: AuthUserPayload,
    @Param('lessonId') lessonId: string,
  ) {
    return this.sessionsService.startSession(user.id, lessonId);
  }

  @Get('sessions/:sessionId')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({ summary: 'Get an active/completed session payload' })
  getOne(
    @CurrentUser() user: AuthUserPayload,
    @Param('sessionId') sessionId: string,
  ) {
    return this.sessionsService.getSession(user.id, sessionId);
  }

  @Post('sessions/:sessionId/submit')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Submit answers; server grades and finalizes the session',
  })
  submit(
    @CurrentUser() user: AuthUserPayload,
    @Param('sessionId') sessionId: string,
    @Body() dto: SubmitSessionDto,
  ) {
    return this.sessionsService.submit(user.id, sessionId, dto);
  }
}

import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MasteryService } from './mastery.service';

@ApiTags('mastery')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('mastery')
export class MasteryController {
  constructor(private readonly masteryService: MasteryService) {}

  @Get('courses/:courseId')
  @ApiOperation({ summary: 'Course mastery score 0–100' })
  getCourseMastery(
    @CurrentUser() user: AuthUserPayload,
    @Param('courseId') courseId: string,
  ) {
    return this.masteryService.getCourseMastery(user.id, courseId);
  }
}

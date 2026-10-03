import {
  Controller,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { PathService } from './path.service';

@ApiTags('path')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('courses/:courseId/path')
export class PathController {
  constructor(private readonly pathService: PathService) {}

  @Post('exams/:position/sessions')
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Start the review exam after lesson #position of the path',
  })
  startExam(
    @CurrentUser() user: AuthUserPayload,
    @Param('courseId', ParseUUIDPipe) courseId: string,
    @Param('position', ParseIntPipe) position: number,
  ) {
    return this.pathService.startExam(user.id, courseId, position);
  }

  @Post('chests/:position/open')
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @ApiOperation({ summary: 'Open the reward chest after lesson #position' })
  openChest(
    @CurrentUser() user: AuthUserPayload,
    @Param('courseId', ParseUUIDPipe) courseId: string,
    @Param('position', ParseIntPipe) position: number,
  ) {
    return this.pathService.openChest(user.id, courseId, position);
  }
}

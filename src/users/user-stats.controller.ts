import { Controller, Get, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { User } from './entities/user.entity';
import { UserStatsService } from './user-stats.service';

@ApiTags('user-stats')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('user-stats')
export class UserStatsController {
  constructor(private readonly userStatsService: UserStatsService) {}

  @Get()
  @ApiOperation({ summary: 'Get current user hearts, gems, and streak' })
  @ApiResponse({ status: 200, description: 'Returns user stats' })
  getStats(@CurrentUser() user: User) {
    return this.userStatsService.getForUser(user.id);
  }

  @Post('decrease-heart')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Decrease one heart (skipped for active Super subscribers)',
  })
  @ApiResponse({ status: 200, description: 'Returns updated stats' })
  @ApiResponse({ status: 400, description: 'No hearts remaining' })
  decreaseHeart(@CurrentUser() user: User) {
    return this.userStatsService.decreaseHeart(user.id);
  }

  @Post('complete-unit')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Mark unit complete: +20 gems and update daily streak',
  })
  @ApiResponse({ status: 200, description: 'Returns updated stats' })
  completeUnit(@CurrentUser() user: User) {
    return this.userStatsService.completeUnit(user.id);
  }

  @Post('refill-hearts')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refill hearts to 5 for 50 gems' })
  @ApiResponse({ status: 200, description: 'Returns updated stats' })
  @ApiResponse({ status: 400, description: 'Not enough gems or hearts already full' })
  refillHearts(@CurrentUser() user: User) {
    return this.userStatsService.refillHearts(user.id);
  }
}

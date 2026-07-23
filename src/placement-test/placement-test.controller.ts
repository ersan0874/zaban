import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { SubmitPlacementDto } from './dto/submit-placement.dto';
import { PlacementTestService } from './placement-test.service';

@ApiTags('placement-test')
@Controller('placement-test')
export class PlacementTestController {
  constructor(private readonly placementTestService: PlacementTestService) {}

  @Get('questions')
  @ApiOperation({
    summary: 'Get 10 standard/hard placement test questions (without answers)',
  })
  @ApiResponse({ status: 200, description: 'Returns placement questions' })
  getQuestions() {
    return this.placementTestService.getQuestions();
  }

  @Post('submit')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Submit placement test answers and set user level' })
  @ApiResponse({
    status: 200,
    description: 'Returns score, percentage, and assigned level',
  })
  submit(@CurrentUser() user: User, @Body() dto: SubmitPlacementDto) {
    return this.placementTestService.submit(user, dto.answers);
  }
}

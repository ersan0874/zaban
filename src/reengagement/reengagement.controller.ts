import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { ReengagementService } from './reengagement.service';

@ApiTags('reengagement')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('reengagement')
export class ReengagementController {
  constructor(private readonly reengagementService: ReengagementService) {}

  @Get('status')
  @ApiOperation({ summary: 'Re-entry diagnostic status after long absence' })
  status(@CurrentUser() user: AuthUserPayload) {
    return this.reengagementService.getStatus(user.id);
  }

  @Post('diagnostic/complete')
  @ApiOperation({
    summary: 'Mark re-entry diagnostic complete (also auto on diagnostic submit)',
  })
  completeDiagnostic(@CurrentUser() user: AuthUserPayload) {
    return this.reengagementService.completeDiagnostic(user.id);
  }
}

import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CoursesService } from './courses.service';

@ApiTags('curriculum')
@Controller()
export class CoursesController {
  constructor(private readonly coursesService: CoursesService) {}

  @Get('courses')
  @ApiOperation({ summary: 'List published courses' })
  listCourses() {
    return this.coursesService.listPublished();
  }

  @Get('courses/:id')
  @ApiOperation({ summary: 'Get course with sections and units' })
  getCourse(@Param('id') id: string) {
    return this.coursesService.getCourse(id);
  }

  @Get('courses/:id/path')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Linear path nodes for learning map UI (checkpoint-aware unlock)',
  })
  getPath(@Param('id') id: string, @CurrentUser() user: AuthUserPayload) {
    return this.coursesService.getPath(id, user.id);
  }

  @Get('units/:unitId')
  @ApiOperation({ summary: 'Unit detail: lessons + words for study' })
  getUnit(@Param('unitId') unitId: string) {
    return this.coursesService.getUnitDetail(unitId);
  }

  @Get('lessons/:lessonId')
  @ApiOperation({
    summary: 'Lesson with exercises (answers omitted unless includeAnswers=1)',
  })
  @ApiQuery({ name: 'includeAnswers', required: false })
  getLesson(
    @Param('lessonId') lessonId: string,
    @Query('includeAnswers') includeAnswers?: string,
  ) {
    return this.coursesService.getLesson(lessonId, {
      includeAnswers: includeAnswers === '1' || includeAnswers === 'true',
    });
  }
}

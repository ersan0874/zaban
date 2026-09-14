import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from './guards/admin.guard';
import { AdminService } from './admin.service';
import { BanUserDto } from './dto/ban-user.dto';
import { CreateCourseDto } from './dto/create-course.dto';
import { UpdateCourseDto } from './dto/update-course.dto';
import { CreateLessonDto } from './dto/create-lesson.dto';
import { UpdateLessonDto } from './dto/update-lesson.dto';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
import { AiService } from '../ai/ai.service';
import { CreateAiJobDto } from '../ai/dto/create-ai-job.dto';
import { BillingService } from '../billing/billing.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly aiService: AiService,
    private readonly billingService: BillingService,
  ) {}

  @Get('users')
  listUsers() {
    return this.adminService.listUsers();
  }

  @Patch('users/:id/ban')
  banUser(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: BanUserDto,
  ) {
    return this.adminService.setUserBanned(id, dto.banned);
  }

  @Get('analytics')
  analytics() {
    return this.adminService.getAnalytics();
  }

  @Get('courses')
  listCourses() {
    return this.adminService.listCourses();
  }

  @Post('courses')
  createCourse(@Body() dto: CreateCourseDto) {
    return this.adminService.createCourse(dto);
  }

  @Patch('courses/:id')
  updateCourse(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCourseDto,
  ) {
    return this.adminService.updateCourse(id, dto);
  }

  @Get('lessons')
  listLessons(@Query('courseId', ParseUUIDPipe) courseId: string) {
    return this.adminService.listLessonsByCourse(courseId);
  }

  @Post('lessons')
  createLesson(@Body() dto: CreateLessonDto) {
    return this.adminService.createLesson(dto);
  }

  @Patch('lessons/:id')
  updateLesson(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateLessonDto,
  ) {
    return this.adminService.updateLesson(id, dto);
  }

  @Get('exercises')
  listExercises(@Query('lessonId', ParseUUIDPipe) lessonId: string) {
    return this.adminService.listExercisesByLesson(lessonId);
  }

  @Post('exercises')
  createExercise(@Body() dto: CreateExerciseDto) {
    return this.adminService.createExercise(dto);
  }

  @Patch('exercises/:id')
  updateExercise(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateExerciseDto,
  ) {
    return this.adminService.updateExercise(id, dto);
  }

  @Get('ai/jobs')
  listAiJobs() {
    return this.aiService.listJobs();
  }

  @Post('ai/jobs')
  createAiJob(
    @CurrentUser() user: { id: string },
    @Body() dto: CreateAiJobDto,
  ) {
    return this.aiService.createJobFromText(
      dto.sourceText,
      dto.createdBy ?? user.id,
    );
  }

  @Post('ai/jobs/:id/approve')
  approveAiJob(@Param('id', ParseUUIDPipe) id: string) {
    return this.aiService.approveJob(id);
  }

  @Get('purchases')
  listPurchases() {
    return this.billingService.listPurchasesForAdmin();
  }
}

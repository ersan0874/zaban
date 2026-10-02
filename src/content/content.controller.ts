import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../admin/guards/admin.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ContentService } from './content.service';
import { CreateContentJobDto } from './dto/create-content-job.dto';
import { SelectProposalDto } from './dto/select-proposal.dto';
import {
  PublishContentJobDto,
  UpdateDraftExerciseDto,
  UpdateDraftLessonDto,
} from './dto/update-draft.dto';

const MAX_FILES = 10;
const MAX_FILE_BYTES = 50 * 1024 * 1024;

@ApiTags('admin-content')
@ApiBearerAuth()
@Controller('admin/content')
@UseGuards(JwtAuthGuard, AdminGuard)
export class ContentController {
  constructor(private readonly content: ContentService) {}

  @Get('question-types')
  questionTypes() {
    return this.content.questionTypes();
  }

  @Post('ping')
  ping() {
    return this.content.ping();
  }

  @Get('jobs')
  listJobs() {
    return this.content.listJobs();
  }

  @Post('jobs')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FilesInterceptor('files', MAX_FILES, {
      storage: memoryStorage(),
      limits: { fileSize: MAX_FILE_BYTES },
    }),
  )
  createJob(
    @UploadedFiles() files: Express.Multer.File[],
    @Body() dto: CreateContentJobDto,
    @CurrentUser() user: { id: string },
  ) {
    return this.content.createJob(files, dto, user?.id ?? null);
  }

  @Get('jobs/:id')
  getJob(@Param('id', ParseUUIDPipe) id: string) {
    return this.content.getJob(id);
  }

  @Get('jobs/:id/source')
  getSource(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('from', ParseIntPipe) from: number,
    @Query('to', ParseIntPipe) to: number,
  ) {
    return this.content.getSource(id, from, to);
  }

  @Post('jobs/:id/proposals/:proposalId/select')
  selectProposal(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('proposalId', ParseUUIDPipe) proposalId: string,
    @Body() dto: SelectProposalDto,
  ) {
    return this.content.selectProposal(id, proposalId, dto.outline);
  }

  @Get('jobs/:id/lessons')
  listLessons(@Param('id', ParseUUIDPipe) id: string) {
    return this.content.listLessons(id);
  }

  @Post('jobs/:id/retry')
  retry(@Param('id', ParseUUIDPipe) id: string) {
    return this.content.retry(id);
  }

  @Post('jobs/:id/publish')
  publish(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: PublishContentJobDto,
  ) {
    return this.content.publish(id, dto);
  }

  @Patch('lessons/:id')
  updateLesson(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateDraftLessonDto,
  ) {
    return this.content.updateLesson(id, dto);
  }

  @Post('lessons/:id/regenerate')
  regenerateLesson(@Param('id', ParseUUIDPipe) id: string) {
    return this.content.regenerateLesson(id);
  }

  @Patch('exercises/:id')
  updateExercise(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateDraftExerciseDto,
  ) {
    return this.content.updateExercise(id, dto);
  }

  @Delete('exercises/:id')
  deleteExercise(@Param('id', ParseUUIDPipe) id: string) {
    return this.content.deleteExercise(id);
  }
}

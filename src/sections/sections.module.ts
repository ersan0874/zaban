import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Section } from './entities/section.entity';
import { SectionsController } from './sections.controller';
import { SectionsService } from './sections.service';

@Module({
  imports: [TypeOrmModule.forFeature([Section])],
  controllers: [SectionsController],
  providers: [SectionsService],
  exports: [SectionsService, TypeOrmModule],
})
export class SectionsModule {}

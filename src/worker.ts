import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

/**
 * Background worker process (Docker `worker` service): runs the AI content
 * pipeline queue and pending essay re-grading without serving HTTP.
 */
async function bootstrap() {
  process.env.AI_WORKER_ENABLED = 'true';
  const app = await NestFactory.createApplicationContext(AppModule);
  app.enableShutdownHooks();
  Logger.log('Zaban worker started', 'Worker');
}
void bootstrap();

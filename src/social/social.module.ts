import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from '../users/users.module';
import { UserGamification } from '../gamification/entities/user-gamification.entity';
import { Friendship } from './entities/friendship.entity';
import { FeedItem } from './entities/feed-item.entity';
import { ChatMessage } from './entities/chat-message.entity';
import { SocialService } from './social.service';
import { SocialController } from './social.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Friendship,
      FeedItem,
      ChatMessage,
      UserGamification,
    ]),
    UsersModule,
  ],
  controllers: [SocialController],
  providers: [SocialService],
  exports: [SocialService],
})
export class SocialModule {}

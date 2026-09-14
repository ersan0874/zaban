import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import {
  CurrentUser,
  type AuthUserPayload,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FriendRequestDto } from './dto/friend-request.dto';
import { ChatMessageDto } from './dto/chat-message.dto';
import { FeedPostDto } from './dto/feed-post.dto';
import { SocialService } from './social.service';

@ApiTags('social')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('social')
export class SocialController {
  constructor(private readonly socialService: SocialService) {}

  @Post('friends/request')
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @ApiOperation({ summary: 'Send friend request by email or user id' })
  requestFriend(
    @CurrentUser() user: AuthUserPayload,
    @Body() body: FriendRequestDto,
  ) {
    return this.socialService.requestFriend(user.id, body.emailOrUserId);
  }

  @Post('friends/:id/accept')
  @ApiOperation({ summary: 'Accept a pending friend request' })
  acceptFriend(
    @CurrentUser() user: AuthUserPayload,
    @Param('id') id: string,
  ) {
    return this.socialService.acceptFriend(user.id, id);
  }

  @Get('friends')
  @ApiOperation({ summary: 'List accepted friends' })
  listFriends(@CurrentUser() user: AuthUserPayload) {
    return this.socialService.listFriends(user.id);
  }

  @Get('friends/streaks')
  @ApiOperation({ summary: 'Friends streak counts (social streak)' })
  friendsStreaks(@CurrentUser() user: AuthUserPayload) {
    return this.socialService.getFriendsStreaks(user.id);
  }

  @Get('feed')
  @ApiOperation({ summary: 'Activity feed (self + friends)' })
  getFeed(@CurrentUser() user: AuthUserPayload) {
    return this.socialService.getFeed(user.id);
  }

  @Post('feed')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOperation({ summary: 'Optional self post to feed' })
  createFeedPost(
    @CurrentUser() user: AuthUserPayload,
    @Body() body: FeedPostDto,
  ) {
    return this.socialService.createFeedPost(
      user.id,
      body.message,
      body.meta ?? {},
    );
  }

  @Get('chat/:peerUserId')
  @ApiOperation({ summary: '1:1 chat history with a friend' })
  getChat(
    @CurrentUser() user: AuthUserPayload,
    @Param('peerUserId') peerUserId: string,
  ) {
    return this.socialService.getChat(user.id, peerUserId);
  }

  @Post('chat/:peerUserId')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiOperation({ summary: 'Send chat message to a friend' })
  sendChat(
    @CurrentUser() user: AuthUserPayload,
    @Param('peerUserId') peerUserId: string,
    @Body() body: ChatMessageDto,
  ) {
    return this.socialService.sendChat(user.id, peerUserId, body.body);
  }
}

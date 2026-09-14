import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { UsersService } from '../users/users.service';
import { UserGamification } from '../gamification/entities/user-gamification.entity';
import {
  Friendship,
  FriendshipStatus,
} from './entities/friendship.entity';
import { FeedItem } from './entities/feed-item.entity';
import { ChatMessage } from './entities/chat-message.entity';

@Injectable()
export class SocialService {
  constructor(
    @InjectRepository(Friendship)
    private readonly friendshipRepository: Repository<Friendship>,
    @InjectRepository(FeedItem)
    private readonly feedRepository: Repository<FeedItem>,
    @InjectRepository(ChatMessage)
    private readonly chatRepository: Repository<ChatMessage>,
    @InjectRepository(UserGamification)
    private readonly gamiRepository: Repository<UserGamification>,
    private readonly usersService: UsersService,
  ) {}

  async requestFriend(userId: string, emailOrUserId: string) {
    const target = await this.resolveUser(emailOrUserId);
    if (target.id === userId) {
      throw new BadRequestException('Cannot friend yourself');
    }

    const existing = await this.friendshipRepository.findOne({
      where: [
        { requesterId: userId, addresseeId: target.id },
        { requesterId: target.id, addresseeId: userId },
      ],
    });
    if (existing) {
      if (existing.status === FriendshipStatus.ACCEPTED) {
        throw new BadRequestException('Already friends');
      }
      throw new BadRequestException('Friend request already pending');
    }

    const friendship = await this.friendshipRepository.save(
      this.friendshipRepository.create({
        requesterId: userId,
        addresseeId: target.id,
        status: FriendshipStatus.PENDING,
      }),
    );

    return {
      id: friendship.id,
      status: friendship.status,
      addressee: {
        id: target.id,
        displayName: target.profile?.displayName ?? target.email,
      },
    };
  }

  async acceptFriend(userId: string, friendshipId: string) {
    const friendship = await this.friendshipRepository.findOne({
      where: { id: friendshipId },
    });
    if (!friendship) {
      throw new NotFoundException('Friend request not found');
    }
    if (friendship.addresseeId !== userId) {
      throw new ForbiddenException('Not your friend request');
    }
    if (friendship.status === FriendshipStatus.ACCEPTED) {
      return { id: friendship.id, status: friendship.status };
    }

    friendship.status = FriendshipStatus.ACCEPTED;
    await this.friendshipRepository.save(friendship);
    return { id: friendship.id, status: friendship.status };
  }

  async listFriends(userId: string) {
    const rows = await this.friendshipRepository.find({
      where: [
        { requesterId: userId, status: FriendshipStatus.ACCEPTED },
        { addresseeId: userId, status: FriendshipStatus.ACCEPTED },
      ],
      relations: {
        requester: { profile: true },
        addressee: { profile: true },
      },
    });

    return rows.map((row) => {
      const peer =
        row.requesterId === userId ? row.addressee : row.requester;
      return {
        friendshipId: row.id,
        userId: peer.id,
        displayName: peer.profile?.displayName ?? peer.email,
        avatarUrl: peer.profile?.avatarUrl ?? null,
      };
    });
  }

  async getFriendsStreaks(userId: string) {
    const friends = await this.listFriends(userId);
    if (friends.length === 0) {
      return { friends: [] };
    }

    const friendIds = friends.map((f) => f.userId);
    const gamiRows = await this.gamiRepository.find({
      where: { userId: In(friendIds) },
    });
    const byUser = new Map(gamiRows.map((g) => [g.userId, g]));

    return {
      friends: friends.map((f) => ({
        userId: f.userId,
        displayName: f.displayName,
        streakCount: byUser.get(f.userId)?.streakCount ?? 0,
      })),
    };
  }

  async getFeed(userId: string, limit = 50) {
    const friendIds = await this.getAcceptedFriendIds(userId);
    const userIds = [userId, ...friendIds];
    const items = await this.feedRepository.find({
      where: { userId: In(userIds) },
      relations: { user: { profile: true } },
      order: { createdAt: 'DESC' },
      take: limit,
    });

    return items.map((item) => ({
      id: item.id,
      userId: item.userId,
      displayName: item.user?.profile?.displayName ?? 'Learner',
      type: item.type,
      message: item.message,
      meta: item.meta,
      createdAt: item.createdAt,
    }));
  }

  async createFeedPost(
    userId: string,
    message: string,
    meta: Record<string, unknown> = {},
  ) {
    return this.publishActivity(userId, 'self_post', message, meta);
  }

  async publishActivity(
    userId: string,
    type: string,
    message: string,
    meta: Record<string, unknown> = {},
  ) {
    const item = await this.feedRepository.save(
      this.feedRepository.create({
        userId,
        type,
        message,
        meta,
      }),
    );
    return { id: item.id, type: item.type, message: item.message };
  }

  async publishLessonComplete(
    userId: string,
    input: { lessonTitle: string; scorePercent: number; xpGained: number },
  ) {
    return this.publishActivity(
      userId,
      'lesson_complete',
      `Completed "${input.lessonTitle}" with ${input.scorePercent}%`,
      {
        scorePercent: input.scorePercent,
        xpGained: input.xpGained,
      },
    );
  }

  async getChat(userId: string, peerUserId: string, limit = 100) {
    await this.ensureCanChat(userId, peerUserId);
    const messages = await this.chatRepository.find({
      where: [
        { fromUserId: userId, toUserId: peerUserId },
        { fromUserId: peerUserId, toUserId: userId },
      ],
      order: { createdAt: 'ASC' },
      take: limit,
    });

    return messages.map((m) => ({
      id: m.id,
      fromUserId: m.fromUserId,
      toUserId: m.toUserId,
      body: m.body,
      createdAt: m.createdAt,
      isMine: m.fromUserId === userId,
    }));
  }

  async sendChat(userId: string, peerUserId: string, body: string) {
    await this.ensureCanChat(userId, peerUserId);
    const trimmed = body.trim();
    if (!trimmed) {
      throw new BadRequestException('Message body required');
    }

    const message = await this.chatRepository.save(
      this.chatRepository.create({
        fromUserId: userId,
        toUserId: peerUserId,
        body: trimmed,
      }),
    );

    return {
      id: message.id,
      fromUserId: message.fromUserId,
      toUserId: message.toUserId,
      body: message.body,
      createdAt: message.createdAt,
    };
  }

  private async ensureCanChat(userId: string, peerUserId: string) {
    const friendship = await this.friendshipRepository.findOne({
      where: [
        {
          requesterId: userId,
          addresseeId: peerUserId,
          status: FriendshipStatus.ACCEPTED,
        },
        {
          requesterId: peerUserId,
          addresseeId: userId,
          status: FriendshipStatus.ACCEPTED,
        },
      ],
    });
    if (!friendship) {
      throw new ForbiddenException('Chat requires accepted friendship');
    }
  }

  private async getAcceptedFriendIds(userId: string): Promise<string[]> {
    const rows = await this.friendshipRepository.find({
      where: [
        { requesterId: userId, status: FriendshipStatus.ACCEPTED },
        { addresseeId: userId, status: FriendshipStatus.ACCEPTED },
      ],
    });
    return rows.map((row) =>
      row.requesterId === userId ? row.addresseeId : row.requesterId,
    );
  }

  private async resolveUser(emailOrUserId: string) {
    const isUuid =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        emailOrUserId,
      );
    const user = isUuid
      ? await this.usersService.findById(emailOrUserId)
      : await this.usersService.findByEmail(emailOrUserId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }
}

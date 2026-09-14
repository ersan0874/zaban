import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';
import { UserProfile } from './entities/user-profile.entity';
import { UserSettings } from './entities/user-settings.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(UserProfile)
    private readonly profilesRepository: Repository<UserProfile>,
    @InjectRepository(UserSettings)
    private readonly settingsRepository: Repository<UserSettings>,
  ) {}

  findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email: email.toLowerCase() },
      relations: { profile: true, settings: true },
    });
  }

  findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { id },
      relations: { profile: true, settings: true },
    });
  }

  async createUser(input: {
    email: string;
    passwordHash: string;
    displayName: string;
    role?: UserRole;
  }): Promise<User> {
    const user = this.usersRepository.create({
      email: input.email.toLowerCase(),
      passwordHash: input.passwordHash,
      refreshTokenHash: null,
      role: input.role ?? UserRole.USER,
      banned: false,
      profile: this.profilesRepository.create({
        displayName: input.displayName,
        avatarUrl: null,
        bio: null,
      }),
      settings: this.settingsRepository.create({
        notificationsEnabled: true,
        dailyReminderEnabled: true,
        marketingEmailsEnabled: false,
      }),
    });

    return this.usersRepository.save(user);
  }

  async setRefreshTokenHash(
    userId: string,
    refreshTokenHash: string | null,
  ): Promise<void> {
    await this.usersRepository.update(userId, { refreshTokenHash });
  }

  async updateProfile(
    userId: string,
    data: Partial<Pick<UserProfile, 'displayName' | 'avatarUrl' | 'bio'>>,
  ): Promise<UserProfile> {
    const profile = await this.profilesRepository.findOne({
      where: { userId },
    });
    if (!profile) {
      throw new NotFoundException('Profile not found');
    }
    Object.assign(profile, data);
    return this.profilesRepository.save(profile);
  }

  async updateSettings(
    userId: string,
    data: Partial<
      Pick<
        UserSettings,
        | 'notificationsEnabled'
        | 'dailyReminderEnabled'
        | 'marketingEmailsEnabled'
      >
    >,
  ): Promise<UserSettings> {
    const settings = await this.settingsRepository.findOne({
      where: { userId },
    });
    if (!settings) {
      throw new NotFoundException('Settings not found');
    }
    Object.assign(settings, data);
    return this.settingsRepository.save(settings);
  }
}

import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { UsersService } from '../users/users.service';
import { ReengagementService } from '../reengagement/reengagement.service';
import { User } from '../users/entities/user.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateSettingsDto } from './dto/update-settings.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly reengagementService: ReengagementService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.usersService.createUser({
      email: dto.email,
      passwordHash,
      displayName: dto.displayName,
    });

    return this.buildAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (user.banned) {
      throw new UnauthorizedException('Account is banned');
    }

    return this.buildAuthResponse(user);
  }

  async refresh(refreshToken: string) {
    let payload: { sub: string; email: string; type?: string };
    try {
      payload = await this.jwtService.verifyAsync(refreshToken, {
        secret: this.configService.get<string>(
          'JWT_REFRESH_SECRET',
          'dev-refresh-secret-change-me',
        ),
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const user = await this.usersService.findById(payload.sub);
    if (!user?.refreshTokenHash) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const matches = await bcrypt.compare(refreshToken, user.refreshTokenHash);
    if (!matches) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    return this.buildAuthResponse(user);
  }

  async logout(userId: string): Promise<{ success: true }> {
    await this.usersService.setRefreshTokenHash(userId, null);
    return { success: true };
  }

  async getMe(userId: string) {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new UnauthorizedException();
    }
    await this.reengagementService.recordActivity(userId);
    return this.toPublicUser(user);
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    await this.usersService.updateProfile(userId, dto);
    return this.getMe(userId);
  }

  async updateSettings(userId: string, dto: UpdateSettingsDto) {
    await this.usersService.updateSettings(userId, dto);
    return this.getMe(userId);
  }

  private async buildAuthResponse(user: User) {
    const tokens = await this.issueTokens(user);
    const refreshHash = await bcrypt.hash(tokens.refreshToken, 10);
    await this.usersService.setRefreshTokenHash(user.id, refreshHash);

    const fresh = await this.usersService.findById(user.id);
    return {
      ...tokens,
      user: this.toPublicUser(fresh ?? user),
    };
  }

  private async issueTokens(user: User) {
    const accessPayload = { sub: user.id, email: user.email, type: 'access' };
    const refreshPayload = { sub: user.id, email: user.email, type: 'refresh' };

    const accessExpires =
      this.configService.get<string>('JWT_ACCESS_EXPIRES') ?? '15m';
    const refreshExpires =
      this.configService.get<string>('JWT_REFRESH_EXPIRES') ?? '7d';

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(accessPayload, {
        secret: this.configService.get<string>(
          'JWT_ACCESS_SECRET',
          'dev-access-secret-change-me',
        ),
        expiresIn: accessExpires as `${number}m` | `${number}d` | number,
      }),
      this.jwtService.signAsync(refreshPayload, {
        secret: this.configService.get<string>(
          'JWT_REFRESH_SECRET',
          'dev-refresh-secret-change-me',
        ),
        expiresIn: refreshExpires as `${number}m` | `${number}d` | number,
      }),
    ]);

    return { accessToken, refreshToken };
  }

  private toPublicUser(user: User) {
    return {
      id: user.id,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
      profile: user.profile
        ? {
            displayName: user.profile.displayName,
            avatarUrl: user.profile.avatarUrl,
            bio: user.profile.bio,
          }
        : null,
      settings: user.settings
        ? {
            notificationsEnabled: user.settings.notificationsEnabled,
            dailyReminderEnabled: user.settings.dailyReminderEnabled,
            marketingEmailsEnabled: user.settings.marketingEmailsEnabled,
          }
        : null,
    };
  }
}

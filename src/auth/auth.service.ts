import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { LessThan, Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { Otp } from './entities/otp.entity';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtPayload } from './strategies/jwt.strategy';

const OTP_EXPIRY_MINUTES = 5;
const BCRYPT_SALT_ROUNDS = 10;

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    @InjectRepository(Otp)
    private readonly otpRepository: Repository<Otp>,
  ) {}

  async requestOtp(dto: RequestOtpDto): Promise<{ message: string }> {
    const receiver = this.resolveReceiver(dto.email, dto.phoneNumber);

    await this.otpRepository.delete({ receiver });

    const code = this.generateOtpCode();
    const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

    await this.otpRepository.save({
      receiver,
      code,
      expiresAt,
    });

    console.log(`[OTP] receiver=${receiver} code=${code} expiresAt=${expiresAt.toISOString()}`);

    return { message: 'OTP sent successfully' };
  }

  async verifyOtp(dto: VerifyOtpDto): Promise<{ access_token: string }> {
    const receiver = this.resolveReceiver(dto.email, dto.phoneNumber);

    const otp = await this.otpRepository.findOne({
      where: { receiver, code: dto.code },
      order: { expiresAt: 'DESC' },
    });

    if (!otp) {
      throw new UnauthorizedException('Invalid OTP code');
    }

    if (otp.expiresAt < new Date()) {
      await this.otpRepository.delete({ id: otp.id });
      throw new UnauthorizedException('OTP has expired');
    }

    await this.otpRepository.delete({ id: otp.id });

    let user: User | null = null;

    if (dto.email) {
      user = await this.usersService.findByEmail(dto.email);
      if (!user) {
        user = await this.usersService.create({
          email: dto.email,
          isVerified: true,
        });
      } else if (!user.isVerified) {
        user.isVerified = true;
        user = await this.usersService.save(user);
      }
    } else if (dto.phoneNumber) {
      user = await this.usersService.findByPhoneNumber(dto.phoneNumber);
      if (!user) {
        user = await this.usersService.create({
          phoneNumber: dto.phoneNumber,
          isVerified: true,
        });
      } else if (!user.isVerified) {
        user.isVerified = true;
        user = await this.usersService.save(user);
      }
    }

    if (!user) {
      throw new BadRequestException('Unable to create or find user');
    }

    return this.generateToken(user);
  }

  async register(dto: RegisterDto): Promise<{ access_token: string }> {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('Email is already registered');
    }

    const hashedPassword = await bcrypt.hash(dto.password, BCRYPT_SALT_ROUNDS);

    const user = await this.usersService.create({
      email: dto.email,
      password: hashedPassword,
      fullName: dto.fullName ?? null,
      isVerified: true,
    });

    return this.generateToken(user);
  }

  async login(dto: LoginDto): Promise<{ access_token: string }> {
    const user = await this.usersService.findByEmailWithPassword(dto.email);
    if (!user || !user.password) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    return this.generateToken(user);
  }

  getProfile(user: User): Omit<User, 'password'> {
    return user;
  }

  async cleanupExpiredOtps(): Promise<void> {
    await this.otpRepository.delete({
      expiresAt: LessThan(new Date()),
    });
  }

  private resolveReceiver(email?: string, phoneNumber?: string): string {
    if (!email && !phoneNumber) {
      throw new BadRequestException('Either email or phoneNumber is required');
    }
    return email ?? phoneNumber!;
  }

  private generateOtpCode(): string {
    const length = Math.random() < 0.5 ? 4 : 5;
    const min = Math.pow(10, length - 1);
    const max = Math.pow(10, length) - 1;
    return String(Math.floor(Math.random() * (max - min + 1)) + min);
  }

  private generateToken(user: User): { access_token: string } {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
    };

    const access_token = this.jwtService.sign(payload);

    return { access_token };
  }
}

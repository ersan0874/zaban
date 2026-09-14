import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('checkpoint_attempts')
@Index(['userId', 'unitId', 'passed'])
export class CheckpointAttempt {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'uuid' })
  unitId: string;

  @Column({ type: 'uuid' })
  lessonId: string;

  @Column({ type: 'int' })
  scorePercent: number;

  @Column({ type: 'boolean' })
  passed: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
}

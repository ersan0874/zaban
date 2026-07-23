import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('otps')
export class Otp {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  receiver: string;

  @Column({ type: 'varchar', length: 10 })
  code: string;

  @Column({ type: 'timestamptz' })
  expiresAt: Date;
}

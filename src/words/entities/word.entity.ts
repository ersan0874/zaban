import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Unit } from '../../units/entities/unit.entity';

export interface WordExample {
  english: string;
  persian: string;
}

@Entity('words')
export class Word {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255, unique: true })
  word: string;

  @Column({ type: 'varchar', length: 500 })
  persianMeaning: string;

  @Column({ type: 'text', array: true, default: [] })
  synonyms: string[];

  @Column({ type: 'jsonb', default: [] })
  examples: WordExample[];

  @Column({ type: 'uuid' })
  unitId: string;

  @ManyToOne(() => Unit, (unit) => unit.words, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'unitId' })
  unit: Unit;
}

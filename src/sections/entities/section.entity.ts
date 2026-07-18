import {
  Column,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Unit } from '../../units/entities/unit.entity';

@Entity('sections')
export class Section {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'int' })
  order: number;

  @OneToMany(() => Unit, (unit) => unit.section, {
    cascade: true,
  })
  units: Unit[];
}

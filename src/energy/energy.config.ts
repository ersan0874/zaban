import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class EnergyConfig {
  constructor(private readonly config: ConfigService) {}

  get cap(): number {
    return Number(this.config.get('ENERGY_CAP', 25));
  }

  get regenIntervalMs(): number {
    return Number(this.config.get('ENERGY_REGEN_MINUTES', 5)) * 60_000;
  }

  get lessonCost(): number {
    return Number(this.config.get('ENERGY_LESSON_COST', 1));
  }

  get comboLength(): number {
    return Number(this.config.get('ENERGY_COMBO_LENGTH', 5));
  }

  get comboRewardMin(): number {
    return Number(this.config.get('ENERGY_COMBO_REWARD_MIN', 1));
  }

  get comboRewardMax(): number {
    return Number(this.config.get('ENERGY_COMBO_REWARD_MAX', 7));
  }
}

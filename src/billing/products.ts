export enum BillingProductId {
  ENERGY_PACK_10 = 'energy_pack_10',
  UNLIMITED_1D = 'unlimited_1d',
  UNLIMITED_1W = 'unlimited_1w',
  UNLIMITED_1M = 'unlimited_1m',
}

export type ProductDefinition = {
  id: BillingProductId;
  label: string;
  energyGrant?: number;
  unlimitedPlan?: 'day' | 'week' | 'month';
};

export const PRODUCTS: Record<BillingProductId, ProductDefinition> = {
  [BillingProductId.ENERGY_PACK_10]: {
    id: BillingProductId.ENERGY_PACK_10,
    label: 'Energy Pack (+10)',
    energyGrant: 10,
  },
  [BillingProductId.UNLIMITED_1D]: {
    id: BillingProductId.UNLIMITED_1D,
    label: 'Unlimited Energy (1 day)',
    unlimitedPlan: 'day',
  },
  [BillingProductId.UNLIMITED_1W]: {
    id: BillingProductId.UNLIMITED_1W,
    label: 'Unlimited Energy (1 week)',
    unlimitedPlan: 'week',
  },
  [BillingProductId.UNLIMITED_1M]: {
    id: BillingProductId.UNLIMITED_1M,
    label: 'Unlimited Energy (1 month)',
    unlimitedPlan: 'month',
  },
};

export function isValidProductId(id: string): id is BillingProductId {
  return id in PRODUCTS;
}

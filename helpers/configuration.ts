import { RAY } from './constants';
import { BigNumber } from 'ethers';

export const TENURE = 42;
export const EPOCH = 14;
export const GRACE_PERIOD = 0;
export const LIQUIDATION_BONUS = 12000;
export const INCOME_RATIO = 5000;
export const OPTIMAL_LIQUIDITY_RATIO = 50000;
export const PROTOCOL_FEE = 100;
export const STALENESS = 6 * 60 * 60;
export const BASE_RATE = BigNumber.from(RAY)
  .div(1000000000000)
  .mul(521428671429);

import { RAY } from './constants';
import { BigNumber } from 'ethers';

export const TENURE = 90;
export const EPOCH = 30;
export const GRACE_PERIOD = 0;
export const LIQUIDATION_BONUS = 10500;
export const INCOME_RATIO = 5000;
export const OPTIMAL_LIQUIDITY_RATIO = 5000;
export const PROTOCOL_FEE = 100;
export const STALENESS = 48 * 60 * 60;
export const BASE_RATE = BigNumber.from(RAY).div(10).mul(2);

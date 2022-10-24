import { RAY } from './constants';
import { BigNumber } from 'ethers';

export const COLLECTION = '0xBd3531dA5CF5857e7CfAA92426877b022e612cf8';
export const LOOKS_RARE = '0x59728544B08AB483533076417FbBB2fD0B17CE3a';
export const TENURE = 90;
export const EPOCH = 30;
export const GRACE_PERIOD = 0;
export const LIQUIDATION_BONUS = 10500;
export const INCOME_RATIO = 5000;
export const OPTIMAL_LIQUIDITY_RATIO = 5000;
export const PROTOCOL_FEE = 100;
export const STALENESS = 6 * 60 * 60;
export const TWAP_TOLERANCE = 2000; // 20%
export const BASE_RATE = BigNumber.from(RAY).div(10).mul(2);

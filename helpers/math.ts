import BigNumber from 'bignumber.js';
import { ethers } from 'ethers';
import { RAY, WAD } from './constants';

export const MAX_UINT_256 =
  '115792089237316195423570985008687907853269984665640564039457584007913129639935';

export const toRay = (n: BigNumber) => {
  return n.multipliedBy(RAY);
};

export const toWad = (value: number) => {
  const n = new BigNumber(value);
  return n.multipliedBy(WAD).toFixed();
};

export const formatBN = (
  n: ethers.BigNumber,
  decimals: number,
  precision: number = 5
) => {
  return new BigNumber(n.toString())
    .shiftedBy(decimals * -1)
    .toFixed(precision);
};

export const decimals = (n: number) => ethers.BigNumber.from(10).pow(n);

export const toEthersBN = (num: BigNumber) =>
  ethers.BigNumber.from(num.toString());

export const toBN = (num: ethers.BigNumber) => new BigNumber(num.toString());

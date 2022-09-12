// ----------------
// MATH
// ----------------

import { BigNumber } from 'ethers';
import { parseUnits } from 'ethers/lib/utils';

export const PERCENTAGE_FACTOR = '10000';
export const HALF_PERCENTAGE = BigNumber.from(PERCENTAGE_FACTOR)
  .div(2)
  .toString();
export const WAD = BigNumber.from(10).pow(18).toString();
export const HALF_WAD = BigNumber.from(WAD).div(2).toString();
export const RAY = BigNumber.from(10).pow(27).toString();
export const HALF_RAY = BigNumber.from(RAY).div(2).toString();
export const WAD_RAY_RATIO = parseUnits('1', 9).toString();
export const oneEther = parseUnits('1', 18);
export const oneRay = parseUnits('1', 27);
export const ONE_YEAR = '31536000';
export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
export const ONE_ADDRESS = '0x0000000000000000000000000000000000000001';

export enum ChainID {
  Mainnet = 1,
  Rinkeby = 4,
  Goerli = 5,
}

/* -------------------------------------------------------------------------- */
/*                                  ADDRESSES                                 */
/* -------------------------------------------------------------------------- */
export const WETH_ADDRESS = {
  [ChainID.Mainnet]: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
  [ChainID.Rinkeby]: '0xc778417E063141139Fce010982780140Aa0cD5Ab',
  [ChainID.Goerli]: '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6',
};

export const TREASURY_ADDRESS = {
  [ChainID.Mainnet]: '0x0000000000000000000000000000000000000000',
  [ChainID.Rinkeby]: '0x7bB17c9401110D05ec39894334cC9d7721E90688',
  [ChainID.Goerli]: '0x7bB17c9401110D05ec39894334cC9d7721E90688',
};

export const RELAY_HUB_ADDRESS = {
  [ChainID.Mainnet]: '0x9e59Ea5333cD4f402dAc320a04fafA023fe3810D',
  [ChainID.Rinkeby]: '0x6650d69225CA31049DB7Bd210aE4671c0B1ca132',
  [ChainID.Goerli]: '0x0000000000000000000000000000000000000000',
};

export const FORWARDER_ADDRESS = {
  [ChainID.Mainnet]: '0xAa3E82b4c4093b4bA13Cb5714382C99ADBf750cA',
  [ChainID.Rinkeby]: '0x83A54884bE4657706785D7309cf46B58FE5f6e8a',
  [ChainID.Goerli]: '0x0000000000000000000000000000000000000000',
};

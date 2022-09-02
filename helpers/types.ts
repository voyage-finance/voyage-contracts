export enum Tranche {
  Junior,
  Senior,
}

export enum ChainID {
  Mainnet = 1,
  Rinkeby = 4,
  Goerli = 5,
  Hardhat = 41337,
}

export const Networks: Record<ChainID, string> = {
  [ChainID.Mainnet]: 'mainnet',
  [ChainID.Rinkeby]: 'rinkeby',
  [ChainID.Goerli]: 'goerli',
  [ChainID.Hardhat]: 'hardhat',
};

export enum Marketplace {
  Looks = 'looksrare',
  Seaport = 'seaport',
}

export enum Token {
  WETH9 = 'weth9',
}

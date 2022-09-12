import { HRE as hre } from './hre';

export function isHardhat() {
  return hre.network.name === 'localhost' || hre.network.name === 'hardhat';
}

export function isTenderly() {
  return hre.network.name === 'tenderly';
}

export function isFork() {
  const isTestChain = isHardhat() || isTenderly();
  return (
    isTestChain &&
    hre.network.config.chainId &&
    hre.network.config.chainId !== 31337
  );
}

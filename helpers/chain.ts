import { ethers } from 'hardhat';

export const timeTravel = async (seconds: number) => {
  await ethers.provider.send('evm_increaseTime', [seconds]);
  await ethers.provider.send('evm_mine', []);
};

export const mine = async (blocks: number, interval: number = 2) => {
  const blocksHex = ethers.utils.hexStripZeros(
    ethers.BigNumber.from(blocks).toHexString()
  );
  const intervalHex = ethers.utils.hexStripZeros(
    ethers.BigNumber.from(interval).toHexString()
  );
  await ethers.provider.send('hardhat_mine', [blocksHex, intervalHex]);
};

export const getCurrentTimestamp = async () => {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  return blockBefore.timestamp;
};

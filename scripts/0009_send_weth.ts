import { Voyage, WETH9 } from '@contracts';
import { ethers } from 'hardhat';
import { MAX_UINT_256 } from '../helpers/math';

async function main() {
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const [, , account] = await ethers.getSigners();
  const address = await account.getAddress();
  let weth = await ethers.getContract<WETH9>('WETH9');
  const tx = await weth.transfer(address, ethers.utils.parseEther('10000'));
  weth = weth.connect(account);
  await weth.approve(voyage.address, MAX_UINT_256);
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

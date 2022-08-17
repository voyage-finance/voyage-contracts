import { ethers, getNamedAccounts, deployments } from 'hardhat';
import { PriceOracle, Voyage } from '@contracts';

async function main() {
  const { owner, alice } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const vaultAddress = await voyage.getVault(owner);
  const weth = await ethers.getContract('WETH9');
  const crab = await ethers.getContract('Crab');
  const marketPlace = await ethers.getContract('MockMarketPlace');
  const looksRareAdapter = await ethers.getContract('LooksRareAdapter');
  await voyage.updateMarketPlaceData(
    marketPlace.address,
    looksRareAdapter.address
  );
  console.log('vault address: ', vaultAddress);
  const { execute } = deployments;
  const priceOracle = await ethers.getContract<PriceOracle>('PriceOracle');
  await priceOracle.updateTwap(crab.address, 300);
  await execute(
    'Voyage',
    {
      from: owner,
      log: true,
      gasLimit: 12450000,
    },
    'previewBuyNowParams',
    crab.address,
    '10'
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

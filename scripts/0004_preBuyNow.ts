import { ethers, getNamedAccounts, deployments } from 'hardhat';
import { PriceOracle, Voyage } from '@contracts';
import { toWad } from '@helpers/math';

async function main() {
  const { owner, alice } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const vaultAddress = await voyage.getVault(owner);
  const weth = await ethers.getContract('WETH9');
  const marketPlace = await ethers.getContract('MockMarketPlace');
  const looksRareAdapter = await ethers.getContract('LooksRareAdapter');
  await voyage.updateMarketPlaceData(
    marketPlace.address,
    looksRareAdapter.address
  );
  console.log('vault address: ', vaultAddress);
  const priceOracle = await ethers.getContract<PriceOracle>('PriceOracle');
  await priceOracle.updateTwap(
    '0xd10E39Afe133eF729aE7f4266B26d173BC5AD1B1',
    toWad(0.0001)
  );
  const param = await voyage.previewBuyNowParams(
    '0xd10E39Afe133eF729aE7f4266B26d173BC5AD1B1'
  );
  console.log('param: ', param);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

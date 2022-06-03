import { deployments, ethers, getNamedAccounts } from 'hardhat';
import crypto from 'crypto';

async function main() {
  const { owner } = await getNamedAccounts();
  const { address: tus } = await deployments.get('Tus');
  const dataProvider = await ethers.getContract('VoyageProtocolDataProvider', owner);
  const poolData = await dataProvider.getPoolData(tus);
  console.log('poolData: ', poolData);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

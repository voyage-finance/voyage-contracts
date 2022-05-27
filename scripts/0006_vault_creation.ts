import { deployments, ethers, getNamedAccounts } from 'hardhat';
import crypto from 'crypto';

async function main() {
  const { owner } = await getNamedAccounts();

  const extCallACL = await ethers.getContract('ExtCallACL', owner);
  const isWhiteList = await extCallACL.isWhitelistedAddress(owner);
  console.log('address is whitelist: ', isWhiteList);

  const { address: treasureUnderSea } = await deployments.get('Tus');
  const voyager = await ethers.getContract('Voyager', owner);
  const random = crypto.randomUUID().substring(7);

  const vaultManagerProxy = await ethers.getContract(
    'VaultManagerProxy',
    owner
  );

  let vaultAddress = await vaultManagerProxy.getVault(owner);
  if (ethers.BigNumber.from(vaultAddress).isZero()) {
    const salt = ethers.utils.formatBytes32String(random);
    vaultAddress = await voyager.createVault(owner, treasureUnderSea, salt);
    console.log('vault created, address is: ', vaultAddress);
  }
  console.log('vault exists, address is: ', vaultAddress);

  const vaultStorage = await ethers.getContract('VaultStorage', owner);
  const vaultA = await vaultStorage.getAllVaults();
  console.log(vaultA);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

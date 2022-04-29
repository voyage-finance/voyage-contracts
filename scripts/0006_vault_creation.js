const { deployments, ethers, getNamedAccounts } = require('hardhat');
const crypto = require('crypto');

async function main() {
  const { owner } = await getNamedAccounts();

  const extCallACL = await ethers.getContract('ExtCallACL', owner);
  const isWhiteList = await extCallACL.isWhitelistedAddress(owner);
  console.log('address is whitelist: ', isWhiteList);

  const { address: treasureUnderSea } = await deployments.get('Tus');
  const voyager = await ethers.getContract('Voyager', owner);
  const random = crypto.randomUUID().substring(7);

  const salt = ethers.utils.formatBytes32String(random);
  await voyager.createVault(owner, treasureUnderSea, salt);

  const vaultManagerProxy = await ethers.getContract(
    'VaultManagerProxy',
    owner
  );
  const vaultAddress = await vaultManagerProxy.getVault(owner);
  console.log('vault created, address is: ', vaultAddress);

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

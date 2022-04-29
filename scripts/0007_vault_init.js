const hre = require('hardhat');
const { deployments, ethers, getNamedAccounts } = hre;

async function main() {
  const { owner } = await getNamedAccounts();
  const { address: tus } = await deployments.get('Tus');
  const voyager = await ethers.getContract('Voyager', owner);
  const extCallACL = await ethers.getContract('ExtCallACL', owner);
  const isWhiteList = await extCallACL.isWhitelistedAddress(owner);
  console.log('address is whitelist: ', isWhiteList);

  const vaultManagerProxy = await ethers.getContract(
    'VaultManagerProxy',
    owner
  );
  const vaultAddress = await vaultManagerProxy.getVault(owner);
  console.log('vault created, address is: ', vaultAddress);
  await voyager.initVault(vaultAddress, tus);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

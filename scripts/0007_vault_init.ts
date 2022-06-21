import { deployments, ethers, getNamedAccounts } from 'hardhat';

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
  const vaultFactory = await ethers.getContractFactory('Vault');
  const vault = vaultFactory.attach(vaultAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

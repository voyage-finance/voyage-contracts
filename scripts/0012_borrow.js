const hre = require('hardhat');
const { deployments, ethers, getNamedAccounts } = hre;

async function main() {
  const { owner } = await getNamedAccounts();
  const vaultManagerProxy = await ethers.getContract(
    'VaultManagerProxy',
    owner
  );
  const vaultAddress = await vaultManagerProxy.getVault(owner);
  const tus = await deployments.get('Tus');

  const voyager = await ethers.getContract('Voyager', owner);
  await voyager.borrow(tus.address, '10000000000000000000', vaultAddress, '0');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

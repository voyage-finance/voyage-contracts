const hre = require('hardhat');
const { ethers, getNamedAccounts } = hre;

async function main() {
  const { owner } = await getNamedAccounts();
  const vaultManagerProxy = await ethers.getContract(
    'VaultManagerProxy',
    owner
  );
  const vaultAddress = await vaultManagerProxy.getVault(owner);

  const tus = await ethers.getContract('Tus', owner);
  const balance = await tus.balanceOf(vaultAddress);
  console.log(balance.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

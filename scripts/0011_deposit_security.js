const hre = require('hardhat');
const { ethers, getNamedAccounts } = hre;

async function main() {
  const { owner } = await getNamedAccounts();
  const vaultManagerProxy = await ethers.getContract(
    'VaultManagerProxy',
    owner
  );
  const vaultAddress = await vaultManagerProxy.getVault(owner);
  const voyager = await ethers.getContract('Voyager', owner);
  const Vault = await ethers.getContractFactory('Vault');

  const escrowAddress = await Vault.attach(
    vaultAddress
  ).getSecurityDepositEscrowAddress();
  console.log('vault escrow address: ', escrowAddress);

  const tus = await ethers.getContract('Tus', owner);
  await voyager.depositMargin(owner, tus.address, '100000000000000000000');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

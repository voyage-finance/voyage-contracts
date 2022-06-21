const hre = require('hardhat');
const { MAX_UINT_256 } = require('../helpers/math');
const { ethers, getNamedAccounts } = hre;

async function main() {
  const { owner } = await getNamedAccounts();
  const vaultManagerProxy = await ethers.getContract(
    'VaultManagerProxy',
    owner
  );
  const vaultAddress = await vaultManagerProxy.getVault(owner);
  console.log('vault created, address is: ', vaultAddress);

  const Vault = await ethers.getContractFactory('Vault');
  const escrowAddress = await Vault.attach(
    vaultAddress
  ).getMarginEscrowAddress();
  console.log('vault escrow address: ', escrowAddress);

  // grant max uint
  const tus = await ethers.getContract('Tus', owner);
  await tus.approve(escrowAddress, MAX_UINT_256);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

require('dotenv').config();
const hre = require('hardhat');
const { deployments, ethers } = hre;

async function main() {
  const { address: treasureUnderSea } = await deployments.get('Tus');
  const { address: vaultManagerProxy } = await deployments.get(
    'VaultManagerProxy'
  );
  const VaultManager = await ethers.getContractFactory('VaultManager');
  console.log('vault manager proxy: ', vaultManagerProxy);
  const vm = await VaultManager.attach(vaultManagerProxy);
  await vm.updateSecurityDepositRequirement(
    treasureUnderSea,
    '100000000000000000000000000'
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

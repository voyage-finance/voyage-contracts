require('dotenv').config();
const hre = require('hardhat');

const { deployments, ethers } = hre;

async function main() {
  const { address: treasureUnderSea } = await deployments.get('Tus');
  const { address: vmp } = await deployments.get('VaultManagerProxy');
  const VaultManager = await ethers.getContractFactory('VaultManager');
  const vm = await VaultManager.attach(vmp);
  await vm.setMarginSecurityDeposit(
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

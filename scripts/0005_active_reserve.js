require('dotenv').config();
const hre = require('hardhat');
const { deployments, ethers } = hre;

async function main() {
  const { address: tus } = await deployments.get('Tus');
  const { address: lmp } = await deployments.get('LiquidityManagerProxy');
  const { address: reserveLogic } = await deployments.get('ReserveLogic');
  const LiquidityManager = await ethers.getContractFactory('LiquidityManager', {
    libraries: { ReserveLogic: reserveLogic },
  });
  const liquidityManager = LiquidityManager.attach(lmp);

  await liquidityManager.activeReserve(tus);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

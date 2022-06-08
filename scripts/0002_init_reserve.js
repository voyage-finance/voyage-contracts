require('dotenv').config();
const hre = require('hardhat');
const { ethers } = hre;

const getAddress = (contract) =>
  hre.deployments.get(contract).then(({ address }) => address);

async function main() {
  const reserveLogic = await getAddress('ReserveLogic');
  const liquidityManagerProxy = await getAddress('LiquidityManagerProxy');
  const LiquidityManager = await ethers
    .getContractFactory('LiquidityManager', {
      libraries: { ReserveLogic: reserveLogic },
    })
    .then((contract) => contract.attach(liquidityManagerProxy));
  const treasureUnderSea = await getAddress('Tus');
  const juniorDepositToken = await getAddress('JuniorDepositToken');
  const seniorDepositToken = await getAddress('SeniorDepositToken');
  const loanStrategy = await getAddress('DefaultLoanStrategy');
  const interestStrategy = await getAddress(
    'DefaultReserveInterestRateStrategy'
  );
  const healthStrategy = await getAddress('DefaultHealthStrategy');

  await LiquidityManager.initReserve(
    treasureUnderSea,
    juniorDepositToken,
    seniorDepositToken,
    interestStrategy,
    healthStrategy,
      loanStrategy,
      '500000000000000000000000000'
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

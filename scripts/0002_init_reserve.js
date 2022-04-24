require('dotenv').config();
const hre = require("hardhat");
const deployedReserveLogic = require('../deployments/' + process.env.HARDHAT_NETWORK + '/ReserveLogic.json');
const deployedLMP = require('../deployments/'+ process.env.HARDHAT_NETWORK + '/LiquidityManagerProxy.json');
const deployedTus = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Tus.json');
const deployedJuniorDepositToken = require('../deployments/' + process.env.HARDHAT_NETWORK + '/JuniorDepositToken.json');
const deployedSeniorDepositToken = require('../deployments/' + process.env.HARDHAT_NETWORK + '/SeniorDepositToken.json');
const deployedStableDebtToken = require('../deployments/' + process.env.HARDHAT_NETWORK + '/StableDebtToken.json');
const deployedInterestedStrategy = require('../deployments/' + process.env.HARDHAT_NETWORK + '/DefaultReserveInterestRateStrategy.json');
const deployedHealthStrategy = require('../deployments/' + process.env.HARDHAT_NETWORK + '/DefaultHealthStrategy.json');
const {ethers} = require("hardhat");

async function main() {
    const liquidityManagerProxy = deployedLMP.address;
    const LiquidityManager = await ethers.getContractFactory("LiquidityManager", { libraries: { ReserveLogic: deployedReserveLogic.address } });
    const liquidityManager = LiquidityManager.attach(liquidityManagerProxy);
    const treasureUnderSea = deployedTus.address;
    const juniorDepositToken = deployedJuniorDepositToken.address;
    const seniorDepositToken = deployedSeniorDepositToken.address;
    const stableDebtToken = deployedStableDebtToken.address;
    const interestStrategy = deployedInterestedStrategy.address;
    const healthStrategy = deployedHealthStrategy.address;

    await liquidityManager.initReserve(
       treasureUnderSea,
        juniorDepositToken,
        seniorDepositToken,
        '100000000000000000000000000',
        '900000000000000000000000000',
        stableDebtToken,
        interestStrategy,
        healthStrategy
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
require('dotenv').config();
const hre = require("hardhat");
const deployedLMP = require('../deployments/' + process.env.HARDHAT_NETWORK + '/LiquidityManagerProxy.json');
const {ethers} = require("hardhat");
const deployedReserveLogic = require('../deployments/' + process.env.HARDHAT_NETWORK + '/ReserveLogic.json');
const deployedTus = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Tus.json');

async function main() {
    const liquidityManagerProxy = deployedLMP.address;
    const LiquidityManager = await ethers.getContractFactory("LiquidityManager", { libraries: { ReserveLogic: deployedReserveLogic.address } });
    const liquidityManager = LiquidityManager.attach(liquidityManagerProxy);
    const treasureUnderSea = deployedTus.address;

    await liquidityManager.activeReserve(
       treasureUnderSea,
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
require('dotenv').config();
const hre = require("hardhat");
const {ethers} = require("hardhat");
const deployedVMP = require('../deployments/' + process.env.HARDHAT_NETWORK + '/VaultManagerProxy.json');
const deployedTus = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Tus.json');


async function main() {
    const treasureUnderSea = deployedTus.address;

    const VaultManager= await hre.ethers.getContractFactory('VaultManager');
    const vm = await VaultManager.attach(deployedVMP.address);
    await vm.updateSecurityDepositRequirement(treasureUnderSea, '100000000000000000000000000');
    await vm.setMaxSecurityDeposit(treasureUnderSea, '100000000000000000000000000')
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
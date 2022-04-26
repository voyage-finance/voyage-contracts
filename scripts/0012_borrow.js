const hre = require("hardhat");
const deployedExtCallACL = require('../deployments/' + process.env.HARDHAT_NETWORK + '/ExtCallACL.json');
const deployedVoyager = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Voyager.json');
const deployedTus = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Tus.json');
const deployedVMP = require('../deployments/' + process.env.HARDHAT_NETWORK + '/VaultManagerProxy.json');
const {ethers} = require("hardhat");

async function main() {
    const owner = process.env.OWNER;
    const VaultManagerProxy = await hre.ethers.getContractFactory('VaultManagerProxy');
    const vaultManagerProxy = await VaultManagerProxy.attach(deployedVMP.address);
    const vaultAddress = await vaultManagerProxy.getVault(owner);
    const treasureUnderSea = deployedTus.address;

    const voyagerAddress = deployedVoyager.address;
    const Voyager = await hre.ethers.getContractFactory('Voyager');
    const voyager = await Voyager.attach(voyagerAddress);
    await voyager.borrow(treasureUnderSea, '10000000000000000000', vaultAddress, '0');

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
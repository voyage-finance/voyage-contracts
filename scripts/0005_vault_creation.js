const hre = require("hardhat");
const deployedExtCallACL = require('../deployments/' + process.env.HARDHAT_NETWORK + '/ExtCallACL.json');
const deployedVoyager = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Voyager.json');
const deployedTus = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Tus.json');
const deployedVMP = require('../deployments/' + process.env.HARDHAT_NETWORK + '/VaultManagerProxy.json');
const deployedVMS = require('../deployments/' + process.env.HARDHAT_NETWORK + '/VaultStorage.json');
const {ethers} = require("hardhat");
const crypto = require('crypto');

async function main() {
    const owner = process.env.OWNER;
    const voyagerAddress = deployedVoyager.address;
    const ExtCallACL = await hre.ethers.getContractFactory('ExtCallACL');
    const extCallACL = await ExtCallACL.attach(deployedExtCallACL.address);
    const isWhiteList = await extCallACL.isWhitelistedAddress(owner);
    console.log('address is whitelist: ', isWhiteList);

    const treasureUnderSea = deployedTus.address;
    const Voyager = await hre.ethers.getContractFactory('Voyager');
    const voyager = await Voyager.attach(voyagerAddress);
    const random = crypto.randomUUID().substring(7);
    console.log(random);

    const salt = ethers.utils.formatBytes32String(random);
    await voyager.createVault('0xf93C5273BA454B40aE2ED316fdF3357dfC3bDAfa',salt);

    const VaultManagerProxy = await hre.ethers.getContractFactory('VaultManagerProxy');
    const vaultManagerProxy = await VaultManagerProxy.attach(deployedVMP.address);
    const vaultAddress = await vaultManagerProxy.getVault(owner);
    console.log('vault created, address is: ', vaultAddress);

    const VaultStorage = await hre.ethers.getContractFactory('VaultStorage');
    const vaultStorageAddress = deployedVMS.address;
    const vaultStorage = await VaultStorage.attach(vaultStorageAddress);
    const vaultA = await vaultStorage.getAllVaults();
    console.log(vaultA);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
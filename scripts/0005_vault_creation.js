const hre = require("hardhat");
const deployedExtCallACL = require('../deployments/' + process.env.HARDHAT_NETWORK + '/ExtCallACL.json');
const deployedVoyager = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Voyager.json');
const deployedTus = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Tus.json');
const deployedVMP = require('../deployments/' + process.env.HARDHAT_NETWORK + '/VaultManagerProxy.json');

async function main() {
    const owner = '0x4C616d9377Fa8d928385F0b11Ab16D4bf0f2d544';
    const voyagerAddress = deployedVoyager.address;
    const ExtCallACL = await hre.ethers.getContractFactory('ExtCallACL');
    const extCallACL = await ExtCallACL.attach(deployedExtCallACL.address);
    const isWhiteList = await extCallACL.isWhitelistedAddress(owner);
    console.log('address is whitelist: ', isWhiteList);

    const treasureUnderSea = deployedTus.address;
    const Voyager = await hre.ethers.getContractFactory('Voyager');
    const voyager = Voyager.attach(voyagerAddress);
    await voyager.createVault(treasureUnderSea);

    const VaultManagerProxy = await hre.ethers.getContractFactory('VaultManagerProxy');
    const vaultManagerProxy = await VaultManagerProxy.attach(deployedVMP.address);
    const vaultAddress = await vaultManagerProxy.getVault(owner);
    console.log('vault created, address is: ', vaultAddress);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
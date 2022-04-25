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

    const currentSecurityDeposit = await vaultManagerProxy.getSecurityDeposit(owner, treasureUnderSea);
    console.log('current security deposit: ', currentSecurityDeposit.toString());

    const voyagerAddress = deployedVoyager.address;
    const Voyager = await hre.ethers.getContractFactory('Voyager');
    const voyager = await Voyager.attach(voyagerAddress);
    const creditLimit = await voyager.getCreditLimit(owner, treasureUnderSea);
    console.log('credit limit: ', creditLimit.toString());

    const availableCreditLimit = await voyager.getAvailableCredit(owner, treasureUnderSea);
    console.log('available credit limit: ', availableCreditLimit.toString());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
const hre = require("hardhat");
const deployedExtCallACL = require('../deployments/' + process.env.HARDHAT_NETWORK + '/ExtCallACL.json');
const deployedVoyager = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Voyager.json');
const deployedTus = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Tus.json');
const deployedVMP = require('../deployments/' + process.env.HARDHAT_NETWORK + '/VaultManagerProxy.json');
const {ethers} = require("hardhat");

async function main() {
    const owner = process.env.OWNER;
    const voyagerAddress = deployedVoyager.address;
    const treasureUnderSea = deployedTus.address;
    const Voyager = await hre.ethers.getContractFactory('Voyager');
    const voyager = Voyager.attach(voyagerAddress);

    const VaultManagerProxy = await hre.ethers.getContractFactory('VaultManagerProxy');
    const vaultManagerProxy = await VaultManagerProxy.attach(deployedVMP.address);
    const vaultAddress = await vaultManagerProxy.getVault(owner);
    console.log('vault created, address is: ', vaultAddress);

    const Vault = await ethers.getContractFactory('Vault');
    const escrowAddress = await Vault.attach(vaultAddress).getSecurityDepositEscrowAddress();
    console.log('vault escrow address: ', escrowAddress);

    const Tus = await hre.ethers.getContractFactory('Tus');
    const tus = await Tus.attach(treasureUnderSea);
    // 100
    await tus.increaseAllowance(escrowAddress, '100000000000000000000');
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
const hre = require("hardhat");
const deployedExtCallACL = require('../deployments/' + process.env.HARDHAT_NETWORK + '/ExtCallACL.json');
const deployedVoyager = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Voyager.json');
const deployedTus = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Tus.json');
const deployedVMP = require('../deployments/' + process.env.HARDHAT_NETWORK + '/VaultManagerProxy.json');

async function main() {
    const owner = process.env.OWNER;
    const voyagerAddress = deployedVoyager.address;
    const treasureUnderSea = deployedTus.address;
    const Voyager = await hre.ethers.getContractFactory('Voyager');
    const voyager = Voyager.attach(voyagerAddress);

    const escrowContract = await voyager.getLiquidityManagerEscrowContractAddress();
    console.log('liquidity escrow contract address: ', escrowContract);

    const Tus = await hre.ethers.getContractFactory('Tus');
    const tus = await Tus.attach(treasureUnderSea);
    await tus.increaseAllowance(escrowContract, '500000000000000000000');
    await voyager.deposit(treasureUnderSea, '1', '500000000000000000000', owner);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
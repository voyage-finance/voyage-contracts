require('dotenv').config();

const deployedVoyager = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Voyager.json');
const hre = require("hardhat");


async function main() {
    const voyagerAddress = deployedVoyager.address;
    const owner = process.env.OWNER;
    const Voyager = await hre.ethers.getContractFactory('Voyager');
    const voyager = Voyager.attach(voyagerAddress);

    await voyager.whitelistAddress([owner]);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
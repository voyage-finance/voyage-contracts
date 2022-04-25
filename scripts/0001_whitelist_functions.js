require('dotenv').config();

const deployedVoyager = require('../deployments/' + process.env.HARDHAT_NETWORK + '/Voyager.json');
const hre = require("hardhat");


async function main() {
    const voyagerAddress = deployedVoyager.address;
    const Voyager = await hre.ethers.getContractFactory('Voyager');
    const voyager = Voyager.attach(voyagerAddress);

    await voyager.whitelistFunction([
        ethers.utils.formatBytes32String('createVault'),
        ethers.utils.formatBytes32String('depositSecurity'),
        ethers.utils.formatBytes32String('redeemSecurity'),
        ethers.utils.formatBytes32String('borrow'),
    ]);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
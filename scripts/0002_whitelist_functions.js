const hre = require("hardhat");

async function main() {
    const voyagerAddress = '0x5e22A3f21751f57536a3Def11B9Ec95bA54E0536';
    const Voyager = await hre.ethers.getContractFactory('Voyager');
    const voyager = Voyager.attach(voyagerAddress);

    await voyager.whitelistFunction([
        ethers.utils.formatBytes32String('createVault'),
        ethers.utils.formatBytes32String('depositSecurity'),
        ethers.utils.formatBytes32String('redeemSecurity'),
    ]);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
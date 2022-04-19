const hre = require("hardhat");

async function main() {
    const voyagerAddress = '0x5e22A3f21751f57536a3Def11B9Ec95bA54E0536';
    const owner = '0x4C616d9377Fa8d928385F0b11Ab16D4bf0f2d544';
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
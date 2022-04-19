const hre = require("hardhat");

async function main() {
    const liquidityManagerProxy = '0x4198D31691492C5454E48143F5DB579b4cfC78Eb';
    const LiquidityManager = await hre.ethers.getContractFactory('LiquidityManager');
    const liquidityManager= LiquidityManager.attach(liquidityManagerProxy);
    const treasureUnderSea = '0x52483caCB11441BFa6f886D8e9E516a1dA26181F';

    await liquidityManager.activeReserve(
       treasureUnderSea,
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
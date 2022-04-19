const hre = require("hardhat");

async function main() {
    const liquidityManagerProxy = '0x4198D31691492C5454E48143F5DB579b4cfC78Eb';
    const LiquidityManager = await hre.ethers.getContractFactory('LiquidityManager');
    const liquidityManager = LiquidityManager.attach(liquidityManagerProxy);
    const treasureUnderSea = '0x52483caCB11441BFa6f886D8e9E516a1dA26181F';
    const juniorDepositToken = '0x2A59f15C3DD4b8769d0edE79269f4a1CD6E52C6B';
    const seniorDepositToken = '0xb53A29Df9703c797D5F278dE20ef30a82e34ABD0';
    const stableDebtToken = '0x66D951f5f80756D683dD917C636304465a37c222';
    const interestStrategy = '0x58C80B14b45Babf49108fF57A30817C187681c22';
    const healthStrategy = '0xB4A18837c31A45B0d787f9c71f5b418E830EC4a4';

    await liquidityManager.initReserve(
       treasureUnderSea,
        juniorDepositToken,
        seniorDepositToken,
        '100000000000000000000000000',
        '900000000000000000000000000',
        stableDebtToken,
        interestStrategy,
        healthStrategy
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
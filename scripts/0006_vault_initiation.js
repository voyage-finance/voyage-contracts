const hre = require("hardhat");

async function main() {
    // const vaultManagerProxyAddr = '0xF2adE463BDF1358c84626d720b707905958a1200';
    const owner = '0x4C616d9377Fa8d928385F0b11Ab16D4bf0f2d544';
    // const tus = '0xf71FBe4b758218064736A2D5864e64cbaEdA199c';
    // const VaultManager = await hre.ethers.getContractFactory('VaultManager');
    // const vaultManager = VaultManager.attach(vaultManagerProxyAddr);
    // await vaultManager.initVault(owner, tus);

    const voyagerAddress = '0x5e22A3f21751f57536a3Def11B9Ec95bA54E0536';
    const MessageBus = await hre.ethers.getContractFactory('MessageBus');
    const messageBus = MessageBus.attach(voyagerAddress);
    const vaultAddr = await messageBus.getVault(owner);
    console.log('vault address: ', vaultAddr);

    const Vault = await hre.ethers.getContractFactory('Vault');
    const vault = await Vault.attach(vaultAddr);
    const vaultVersion = await vault.getVersion();
    console.log('vault version: ', vaultVersion);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
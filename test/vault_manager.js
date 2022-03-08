const { expect } = require("chai");

describe("SecurityDepositEscrow contract", function () {
    it("Deployed Vault should init correct role", async function () {
        const [owner] = await ethers.getSigners();
        const Voyager = await ethers.getContractFactory("Voyager");
        const voyager = await Voyager.deploy();
        
        const VaultManager = await ethers.getContractFactory("VaultManager");
        const vaultManager = await VaultManager.deploy(voyager.address);

        const voyagerRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("VOYAGER"));
        expect(await vaultManager.hasRole(voyagerRole,voyager.address)).to.equal(true);
    });

    it("Create Vault should return a valid vault contract", async function () {
        const [owner] = await ethers.getSigners();

        // deploy Voyager contract
        const Voyager = await ethers.getContractFactory("Voyager");
        const voyager = await Voyager.deploy();

        // deploy AddressResolver contract
        const AddressResolver = await ethers.getContractFactory("AddressResolver");
        const addressResolver = await AddressResolver.deploy();

        // set AddressResolver address to Voyager
        voyager.setAddressResolverAddress(addressResolver.address);

        // deploy VaultManager contract
        const VaultManager = await ethers.getContractFactory("VaultManager");
        const vaultManager = await VaultManager.deploy(voyager.address);

        // deploy VaultStorage contract
        const VaultStorage = await ethers.getContractFactory("VaultStorage");
        const vaultStorage = await VaultStorage.deploy(vaultManager.address);

        // import vaultManager to AddressResolver
        const names = [ethers.utils.formatBytes32String("vaultManager"),ethers.utils.formatBytes32String("vaultStorage")];
        const destinations = [vaultManager.address, vaultStorage.address];
        const importTxn = await addressResolver.importAddresses(names, destinations);

        // create vault
        await voyager.createVault();

        const allVaults = await vaultStorage.getAllCreditAccount();
        const vaultAddress = await vaultStorage.getCreditAccount(owner.address);

        console.log(vaultAddress);
        const Vault = await ethers.getContractFactory("Vault");
        const vault = Vault.attach(vaultAddress);

        expect(await vault.getVersion()).to.equal("0.0.1");
    })
});


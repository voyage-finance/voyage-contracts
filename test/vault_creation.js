const { expect } = require("chai");


let voyager;
let vaultStorage;

describe("SecurityDepositEscrow contract", function () {

    beforeEach(async function () {

        // deploy Voyager contract
        const Voyager = await ethers.getContractFactory("Voyager");
        voyager = await Voyager.deploy();

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
        vaultStorage = await VaultStorage.deploy(vaultManager.address);

        // import vaultManager to AddressResolver
        const names = [ethers.utils.formatBytes32String("vaultManager"),ethers.utils.formatBytes32String("vaultStorage")];
        const destinations = [vaultManager.address, vaultStorage.address];
        await addressResolver.importAddresses(names, destinations);
    });

    it("New user should have zero address vault", async function () {
        expect(await voyager.getVault()).to.equal("0x0000000000000000000000000000000000000000");
    })

    it("Create Vault should return a valid vault contract", async function () {

        const [owner] = await ethers.getSigners();
        // create vault
        await voyager.createVault();

        const vaultAddress = await vaultStorage.getVaultAddress(owner.address);
        const Vault = await ethers.getContractFactory("Vault");
        const vault = Vault.attach(vaultAddress);
        expect(await vault.getVersion()).to.equal("Vault 0.0.1");

    })

    it("Created Vault should have own a valid escrow contract", async function () {

        const [owner] = await ethers.getSigners();
        // create vault
        await voyager.createVault();

        const vaultAddress = await vaultStorage.getVaultAddress(owner.address);
        const Vault = await ethers.getContractFactory("Vault");
        const vault = Vault.attach(vaultAddress);

        const SecurityDepositEscrow = await ethers.getContractFactory("SecurityDepositEscrow");
        const securityDepositEscrowAddress = await vault.getSecurityDepositEscrowAddress();
        const securityDepositEscrow = SecurityDepositEscrow.attach(securityDepositEscrowAddress);
        expect(await securityDepositEscrow.getVersion()).to.equal("SecurityDepositEscrow 0.0.1");

    })
});


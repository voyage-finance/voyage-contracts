const { expect } = require("chai");


let voyager;
let vaultManagerProxy;
let vaultManager;
let vaultStorage;
let owner;

describe("Vault Creation", function () {

    beforeEach(async function () {
         [owner] = await ethers.getSigners();

        // deploy Voyager contract
        const Voyager = await ethers.getContractFactory("Voyager");
        voyager = await Voyager.deploy(owner.address);

        // deploy AddressResolver contract
        const AddressResolver = await ethers.getContractFactory("AddressResolver");
        const addressResolver = await AddressResolver.deploy();

        // set AddressResolver address to Voyager
        await voyager.setAddressResolverAddress(addressResolver.address);

        // deploy VaultManagerProxy contract
        const VaultManagerProxy = await ethers.getContractFactory("VaultManagerProxy");
        vaultManagerProxy = await VaultManagerProxy.deploy();

        // deploy VaultManager contract
        const VaultManager = await ethers.getContractFactory("VaultManager");
        vaultManager = await VaultManager.deploy(vaultManagerProxy.address,voyager.address);

        // update VaultManagerProxy, set target contract
        vaultManagerProxy.setTarget(vaultManager.address);

        // deploy VaultStorage contract
        const VaultStorage = await ethers.getContractFactory("VaultStorage");
        vaultStorage = await VaultStorage.deploy(vaultManager.address);

        // import vaultManager to AddressResolver
        const names = [ethers.utils.formatBytes32String("vaultManagerProxy"),ethers.utils.formatBytes32String("vaultStorage")];
        const destinations = [vaultManagerProxy.address, vaultStorage.address];
        await addressResolver.importAddresses(names, destinations);

        await vaultManagerProxy.transferOwnership(voyager.address);
        await voyager.claimVaultManagerProxyOwnership();
    });

    it("New user should have zero address vault", async function () {
        expect(await vaultManager.getVault(owner.address)).to.equal("0x0000000000000000000000000000000000000000");
    })


    it("Create Vault should return a valid vault contract", async function () {

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


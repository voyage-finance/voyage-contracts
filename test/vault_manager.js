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
});


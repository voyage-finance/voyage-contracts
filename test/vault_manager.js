const { expect } = require("chai");

describe("SecurityDepositEscrow contract", function () {
    it("Deployment should give the deployer the ownership", async function () {
        const [owner] = await ethers.getSigners();
        const SecurityDepositEscrow = await ethers.getContractFactory("SecurityDepositEscrow");
        const securityDepositEscrow = await SecurityDepositEscrow.deploy();
        expect(await securityDepositEscrow.owner()).to.equal(owner.address);
    });
});


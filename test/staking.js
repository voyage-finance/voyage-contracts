const { expect } = require("chai");

let owner;
let tus;
let securityDepositToken;
let stakingRewards;

describe("Staking contract", function () {
    beforeEach(async function () {
        [owner] = await ethers.getSigners();

        // deploy underlying asset
        const Tus = await ethers.getContractFactory("Tus");
        tus = await Tus.deploy("1000000000000000000000");

        // deploy security deposit token
        const SecurityDepositToken = await ethers.getContractFactory("SecurityDepositToken");
        securityDepositToken = await SecurityDepositToken.deploy(tus.address, 18, "Treasure Under Sea", "TUS");

        const StakingRewards = await ethers.getContractFactory("StakingRewards");
        stakingRewards = await StakingRewards.deploy(tus.address, securityDepositToken.address);

    });

    it("Deployment should give the deployer the ownership", async function () {
        expect(await stakingRewards.owner()).to.equal(owner.address);
    });

    it("New deployed staking contract should have 0 total supply", async  function() {
        expect(await stakingRewards.totalSupply()).to.equal("0");

    })
});
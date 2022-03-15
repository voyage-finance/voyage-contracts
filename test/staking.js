const { expect } = require("chai");
const {network} = require("hardhat");

let owner;
let tus;
let securityDepositToken;
let stakingRewards;

describe("Staking contract", function () {
    beforeEach(async function () {
        [owner] = await ethers.getSigners();

        // deploy underlying asset
        const Tus = await ethers.getContractFactory("Tus");
        tus = await Tus.deploy("100000000000000000000");

        // deploy security deposit token
        // attention: we use mock TUS contract, not actual SecurityDepositToken contract to avoid minting
        const SecurityDepositToken = await ethers.getContractFactory("Tus");
        securityDepositToken = await SecurityDepositToken.deploy("100000000000000000000");

        const StakingRewards = await ethers.getContractFactory("StakingRewards");
        stakingRewards = await StakingRewards.deploy(securityDepositToken.address, tus.address);

        // increase allowance
        await securityDepositToken.increaseAllowance(stakingRewards.address, "100000000000000000000");

        // set rewardsDistribution
        await stakingRewards.setRewardsDistribution(owner.address);

    });

    it("Deployment should give the deployer the ownership", async function () {
        expect(await stakingRewards.owner()).to.equal(owner.address);
    });

    it("New deployed staking contract should have 0 total supply", async  function() {
        expect(await stakingRewards.totalSupply()).to.equal("0");
    })

    it("Stake with no rewards should get no rewards", async  function() {
        const sevenDays = 7 * 24 * 60 * 60;

        // before increasing time, stake some
        await stakingRewards.stake("10000");

        // increase seven days
        await ethers.provider.send('evm_increaseTime', [sevenDays]);
        await ethers.provider.send('evm_mine');

        const earned = await stakingRewards.earned(owner.address);
        expect(earned).to.equal("0");
    })

    it("Single user stake with rewards should get all rewards", async  function() {
        const sevenDays = 7 * 24 * 60 * 60;

        // transfer tus to staking contract
        await tus.transfer(stakingRewards.address, "10000000000000000000");
        // before increasing time, stake some
        await stakingRewards.stake("10000000000000000000");
        const notifyTxn = await stakingRewards.notifyRewardAmount("1000000000000000000");
        console.log(notifyTxn);

        // increase seven days
        await ethers.provider.send('evm_increaseTime', [sevenDays]);
        await ethers.provider.send('evm_mine');

        // 999999999999907200
        // 1000000000000000000
        const earned = await stakingRewards.earned(owner.address);
        expect(earned).to.equal("999999999999907200");
        await expect(stakingRewards.getReward()).to.emit(stakingRewards, 'RewardPaid').withArgs(owner.address,"999999999999907200")

    })


});
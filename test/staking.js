const { expect } = require("chai");

// describe("Staking contract", function () {
//     it("Deployment should give the deployer the ownership", async function () {
//         const [owner] = await ethers.getSigners();
//         const StakingRewards = await ethers.getContractFactory("StakingRewards");
//         const fakeAddress = "0xf693248F96Fe03422FEa95aC0aFbBBc4a8FdD172";
//         const stakingRewards = await StakingRewards.deploy(fakeAddress, fakeAddress,fakeAddress);
//         expect(await stakingRewards.owner()).to.equal(owner.address);
//     });
// });
const { expect } = require('chai');
const { network } = require('hardhat');

let owner;
let tus;
let securityDepositToken;
let stakingRewards;
let anotherUser;

describe('Staking contract', function () {
  beforeEach(async function () {
    [owner, anotherUser] = await ethers.getSigners();

    // deploy underlying asset
    const Tus = await ethers.getContractFactory('Tus');
    tus = await Tus.deploy('100000000000000000000');

    // deploy security deposit token
    // attention: we use mock TUS contract, not actual SecurityDepositToken contract to avoid minting stuff
    // but overall it's ok as they all ERC20 token
    const SecurityDepositToken = await ethers.getContractFactory('Tus');
    securityDepositToken = await SecurityDepositToken.deploy(
      '100000000000000000000'
    );

    const StakingRewards = await ethers.getContractFactory('StakingRewards');
    stakingRewards = await StakingRewards.deploy(
      securityDepositToken.address,
      tus.address
    );

    // increase allowance
    await securityDepositToken.increaseAllowance(
      stakingRewards.address,
      '100000000000000000000'
    );

    // set rewardsDistribution
    await stakingRewards.setRewardsDistribution(owner.address);
  });

  it('Deployment should give the deployer the ownership', async function () {
    expect(await stakingRewards.owner()).to.equal(owner.address);
  });

  it('New deployed staking contract should have 0 total supply', async function () {
    expect(await stakingRewards.totalSupply()).to.equal('0');
  });

  it('Stake with no rewards should get no rewards', async function () {
    const sevenDays = 7 * 24 * 60 * 60;

    // before increasing time, stake some
    await stakingRewards.stake('10000');

    // increase seven days
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine');

    const earned = await stakingRewards.earned(owner.address);
    expect(earned).to.equal('0');
  });

  it('Single user stake with rewards should get all rewards', async function () {
    const oneDay = 24 * 60 * 60;
    const fourDays = 4 * oneDay;

    // transfer tus to staking contract
    await tus.transfer(stakingRewards.address, '10000000000000000000');
    // before increasing time, stake some
    await stakingRewards.stake('10000000000000000000');
    await stakingRewards.notifyRewardAmount('1000000000000000000');

    await ethers.provider.send('evm_increaseTime', [oneDay]);
    await ethers.provider.send('evm_mine');
    const earned0 = await stakingRewards.earned(owner.address);
    // expect(earned0).to.equal('142857142857129600');

    await ethers.provider.send('evm_increaseTime', [oneDay]);
    await ethers.provider.send('evm_mine');
    const earned1 = await stakingRewards.earned(owner.address);
    // expect(earned1).to.equal('285714285714259200');

    await ethers.provider.send('evm_increaseTime', [oneDay]);
    await ethers.provider.send('evm_mine');
    const earned2 = await stakingRewards.earned(owner.address);
    // expect(earned2).to.equal('428571428571388800');

    await ethers.provider.send('evm_increaseTime', [fourDays]);
    await ethers.provider.send('evm_mine');
    // 142857142857129600 * 7
    // await expect(stakingRewards.getReward())
    //   .to.emit(stakingRewards, 'RewardPaid')
    //   .withArgs(owner.address, '999999999999907200');

    // withdraw principal
    await expect(stakingRewards.withdraw('10000000000000000000'))
      .to.emit(stakingRewards, 'Withdrawn')
      .withArgs(owner.address, '10000000000000000000');
  });

  it('Two user equally stake should return correct rewards', async function () {
    const oneDay = 24 * 60 * 60;
    const sixDays = 6 * 24 * 60 * 60;

    // transfer half sd token from owner to another user
    await securityDepositToken.transfer(
      anotherUser.address,
      '50000000000000000000'
    );

    // increase allowance for another user
    await securityDepositToken
      .connect(anotherUser)
      .increaseAllowance(stakingRewards.address, '50000000000000000000');

    // transfer tus to staking contract
    await tus.transfer(stakingRewards.address, '10000000000000000000');

    // before increasing time, stake some
    await stakingRewards.stake('50000000000000000000');
    await stakingRewards.connect(anotherUser).stake('50000000000000000000');

    await stakingRewards.notifyRewardAmount('1000000000000000000');

    await ethers.provider.send('evm_increaseTime', [oneDay]);
    await ethers.provider.send('evm_mine');
    const earned0 = await stakingRewards.earned(owner.address);
    // expect(earned0).to.equal('71428571428564800');
    await ethers.provider.send('evm_increaseTime', [sixDays]);
    await ethers.provider.send('evm_mine');
    await expect(stakingRewards.getReward())
      .to.emit(stakingRewards, 'RewardPaid')
      .withArgs(owner.address, '499999999999953600');
  });
});

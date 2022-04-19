const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { ethers, deployments, getNamedAccounts } = require('hardhat');

let owner;
let voyager;
let liquidityManager;
let liquidityManagerProxy;
let tus;
let escrowContract;
let juniorDepositToken;
let seniorDepositToken;
let stableDebtToken;
let defaultReserveInterestRateStrategy;
let healthStrategyAddress;

describe('Reserve Deposit', function () {
  beforeEach(async function () {
    ({ owner } = await getNamedAccounts());
    await deployments.fixture([
      'AddressResolver',
      'Voyager',
      'ACLManager',
      'LiquidityManagerProxy',
      'LiquidityManager',
      'LiquidityManagerStorage',
      'Tokenization',
      'SetAddressResolver'
    ]);
    const addressResolver = await ethers.getContract('AddressResolver');

    voyager = await ethers.getContract('Voyager');
    await voyager.setAddressResolverAddress(addressResolver.address);

    tus = await ethers.getContract('Tus');
    liquidityManager = await ethers.getContract('LiquidityManager');
    liquidityManagerProxy = await ethers.getContract('LiquidityManagerProxy');
    juniorDepositToken = await ethers.getContract('JuniorDepositToken');
    seniorDepositToken = await ethers.getContract('SeniorDepositToken');
    stableDebtToken = await ethers.getContract('StableDebtToken');
    defaultReserveInterestRateStrategy = await ethers.getContract('DefaultReserveInterestRateStrategy');
    healthStrategyAddress = await ethers.getContract('DefaultHealthStrategy');

    const isDeployed = await liquidityManager.deployed();
    console.log('liquidityManager deployed address: ', isDeployed.address)

    const LM = await ethers.getContractFactory("LiquidityManager");
    const lm = await LM.attach(liquidityManagerProxy.address);
    const proxyTarget = await liquidityManagerProxy.target()
    console.log('lm proxy target: ', proxyTarget);
    console.log('lm address: ', liquidityManager.address);
    await lm.initReserve(
        tus.address,
        juniorDepositToken.address,
        seniorDepositToken.address,
        '100000000000000000000000000',
        '900000000000000000000000000',
        stableDebtToken.address,
        defaultReserveInterestRateStrategy.address,
        healthStrategyAddress.address
    );
    console.log('successfully init reserve')
    await lm.activeReserve(tus.address);

    const reserveFlags = await voyager.getReserveFlags(tus.address);
    expect(reserveFlags[0]).to.equal(true);
    expect(reserveFlags[1]).to.equal(false);
    expect(reserveFlags[2]).to.equal(false);

    escrowContract = await voyager.getLiquidityManagerEscrowContractAddress();
    await tus.increaseAllowance(escrowContract, '100000000000000000000');

    const aclManager = await ethers.getContract('ACLManager')
    await aclManager.grantLiquidityManager(owner);
    await aclManager.grantLiquidityManagerContract(liquidityManager.address);
  });

  it('Deposit junior liquidity should return correct value', async function () {
    const depositAmount = '1000000000000000000';
    await voyager.deposit(tus.address, 0, depositAmount, owner);
    const juniorTokenAmount = await juniorDepositToken.balanceOf(owner);
    expect(juniorTokenAmount).to.equal(BigNumber.from(depositAmount));
    expect(await tus.balanceOf(escrowContract)).to.equal(
      BigNumber.from(depositAmount)
    );

    expect(await voyager.liquidityRate(tus.address, '0')).to.equal('0');
    // deposit again
    await voyager.deposit(tus.address, 0, depositAmount, owner);
    expect(await voyager.liquidityRate(tus.address, '0')).to.equal('0');
  });

  it('Deposit senior liquidity should return correct value', async function () {
    const depositAmount = '1000000000000000000';
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    const seniorTokenAmount = await seniorDepositToken.balanceOf(owner);
    expect(seniorTokenAmount).to.equal(BigNumber.from(depositAmount));

    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
    // deposit again
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
  });
});

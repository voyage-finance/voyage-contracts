const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { ethers, deployments, getNamedAccounts } = require('hardhat');
const { MAX_UINT_256 } = require('../helpers/math');

let owner;
let voyager;
let liquidityManager;
let liquidityManagerProxy;
let tus;
let escrowContract;
let juniorDepositToken;
let seniorDepositToken;
let defaultReserveInterestRateStrategy;
let healthStrategyAddress;
let loanStrategy;

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
      'SetAddressResolver',
      'LoanManager',
    ]);
    const addressResolver = await ethers.getContract('AddressResolver');

    voyager = await ethers.getContract('Voyager');
    await voyager.setAddressResolverAddress(addressResolver.address);

    tus = await ethers.getContract('Tus');
    liquidityManagerProxy = await ethers.getContract('LiquidityManagerProxy');
    liquidityManager = await ethers.getContract('LiquidityManager');
    juniorDepositToken = await ethers.getContract('JuniorDepositToken');
    seniorDepositToken = await ethers.getContract('SeniorDepositToken');
    defaultReserveInterestRateStrategy = await ethers.getContract(
      'DefaultReserveInterestRateStrategy'
    );
    healthStrategyAddress = await ethers.getContract('DefaultHealthStrategy');
    loanStrategy = await ethers.getContract('DefaultLoanStrategy');

    await liquidityManager.deployed();

    const reserveLogic = await ethers.getContract('ReserveLogic');
    const LM = await ethers.getContractFactory('LiquidityManager', {
      libraries: { ReserveLogic: reserveLogic.address },
    });
    const lm = await LM.attach(liquidityManagerProxy.address);
    await lm.initReserve(
      tus.address,
      juniorDepositToken.address,
      seniorDepositToken.address,
      defaultReserveInterestRateStrategy.address,
      healthStrategyAddress.address,
      loanStrategy.address,
      '500000000000000000000000000'
    );
    await expect(lm.activeReserve(tus.address))
      .to.emit(lm, 'ReserveActivated')
      .withArgs(tus.address);

    const reserveFlags = await voyager.getReserveFlags(tus.address);
    expect(reserveFlags[0]).to.equal(true);
    expect(reserveFlags[1]).to.equal(false);
    expect(reserveFlags[2]).to.equal(false);

    await tus.approve(liquidityManager.address, MAX_UINT_256);

    const aclManager = await ethers.getContract('ACLManager');
    await aclManager.grantLiquidityManager(owner);
    await aclManager.grantLiquidityManagerContract(liquidityManager.address);
  });

  it('Deposit junior liquidity should return correct value', async function () {
    const depositAmount = '1000000000000000000';
    const lm = liquidityManager.attach(liquidityManagerProxy.address);
    await expect(voyager.deposit(tus.address, 0, depositAmount))
      .to.emit(lm, 'Deposit')
      .withArgs(tus.address, owner, 0, depositAmount);
    const juniorTokenAmount = await juniorDepositToken.balanceOf(owner);
    expect(juniorTokenAmount).to.equal(BigNumber.from(depositAmount));

    // deposit again
    await expect(voyager.deposit(tus.address, 0, depositAmount))
      .to.emit(lm, 'Deposit')
      .withArgs(tus.address, owner, 0, depositAmount);
    expect(await voyager.liquidityRate(tus.address, '0')).to.equal('0');
  });

  it('Deposit senior liquidity should return correct value', async function () {
    const depositAmount = '1000000000000000000';
    await voyager.deposit(tus.address, 1, depositAmount);
    const seniorTokenAmount = await seniorDepositToken.balanceOf(owner);
    expect(seniorTokenAmount).to.equal(BigNumber.from(depositAmount));

    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
    // deposit again
    await voyager.deposit(tus.address, 1, depositAmount);
    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
  });
});

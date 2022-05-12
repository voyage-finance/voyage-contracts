const { expect } = require('chai');
const { deployments, ethers, getNamedAccounts } = require('hardhat');
const { BigNumber } = require('ethers');

let owner;
let voyager;
let liquidityManagerProxy;
let liquidityManager;
let juniorDepositToken;
let seniorDepositToken;
let stableDebtToken;
let defaultReserveInterestRateStrategy;
let healthStrategyAddress;
let addressResolver;
let vaultManager;
let tus;
let vm;
let lm;
let dp;
let vaultAddr;

const RAY = BigNumber.from('1000000000000000000000000000');

describe('Liquidity Rate', function () {
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
      'VaultManager',
      'VoyageProtocolDataProvider',
    ]);
    liquidityManagerProxy = await ethers.getContract('LiquidityManagerProxy');
    liquidityManager = await ethers.getContract('LiquidityManager');
    juniorDepositToken = await ethers.getContract('JuniorDepositToken');
    seniorDepositToken = await ethers.getContract('SeniorDepositToken');
    stableDebtToken = await ethers.getContract('StableDebtToken');
    defaultReserveInterestRateStrategy = await ethers.getContract(
      'DefaultReserveInterestRateStrategy'
    );
    healthStrategyAddress = await ethers.getContract('DefaultHealthStrategy');
    addressResolver = await ethers.getContract('AddressResolver');
    tus = await ethers.getContract('Tus');
    voyager = await ethers.getContract('Voyager');
    vaultManager = await ethers.getContract('VaultManager');
    await voyager.whitelistAddress([owner]);
    await voyager.whitelistFunction([
      ethers.utils.formatBytes32String('createVault'),
      ethers.utils.formatBytes32String('depositSecurity'),
      ethers.utils.formatBytes32String('redeemSecurity'),
      ethers.utils.formatBytes32String('borrow'),
    ]);
    await tus.increaseAllowance(
      liquidityManager.address,
      '1000000000000000000000'
    );

    const vaultManagerProxy = await ethers.getContract('VaultManagerProxy');
    const VaultManager = await ethers.getContractFactory('VaultManager');
    vm = await VaultManager.attach(vaultManagerProxy.address);

    const reserveLogic = await ethers.getContract('ReserveLogic');
    const LM = await ethers.getContractFactory('LiquidityManager', {
      libraries: { ReserveLogic: reserveLogic.address },
    });
    lm = await LM.attach(liquidityManagerProxy.address);
    await lm.initReserve(
      tus.address,
      juniorDepositToken.address,
      seniorDepositToken.address,
      stableDebtToken.address,
      defaultReserveInterestRateStrategy.address,
      healthStrategyAddress.address,
      '500000000000000000000000000'
    );
    const DataProvider = await ethers.getContract('VoyageProtocolDataProvider');
    dp = await DataProvider.attach(DataProvider.address);
    await lm.activeReserve(tus.address);
    await vm.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
    await vm.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);

    // get security deposit escrow address
    const Vault = await ethers.getContractFactory('Vault');
    const escrowAddress = await Vault.attach(
      vaultAddr
    ).getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(escrowAddress, '1000000000000000000000');
  });

  it('No borrow should return zero interest rate on deposit', async function () {
    const seniorDepositAmount = '500000000000000000000';
    const juniorDepositAmount = '100000000000000000000';

    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    await voyager.deposit(tus.address, 1, seniorDepositAmount, owner);
    const poolData = await dp.getPoolData(tus.address);

    const juniorLiquidityRate = poolData.juniorLiquidityRate / RAY;
    const seniorLiquidityRate = poolData.seniorLiquidityRate / RAY;

    expect(juniorLiquidityRate.toPrecision(4)).to.equal('0.000');
    expect(seniorLiquidityRate.toPrecision(4)).to.equal('0.000');
  });

  it.only('Junior deposit should return correct interest rate', async function () {
    const seniorDepositAmount = '500000000000000000000';
    const juniorDepositAmount = '100000000000000000000';

    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    await voyager.deposit(tus.address, 1, seniorDepositAmount, owner);
    await voyager.depositSecurity(owner, tus.address, '100000000000000000000');

    await voyager.borrow(tus.address, '400000000000000000000', vaultAddr, 0);
    const poolData = await dp.getPoolData(tus.address);

    const juniorLiquidityRate = poolData.juniorLiquidityRate / RAY;
    const seniorLiquidityRate = poolData.seniorLiquidityRate / RAY;

    console.log('junior liquidity rate: ', juniorLiquidityRate.toPrecision(4));
    console.log('senior liquidity rate: ', seniorLiquidityRate.toPrecision(4));

    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    const poolData1 = await dp.getPoolData(tus.address);
    const juniorLiquidityRate1 = poolData1.juniorLiquidityRate / RAY;
    const seniorLiquidityRate1 = poolData1.seniorLiquidityRate / RAY;

    console.log('junior liquidity rate: ', juniorLiquidityRate1.toPrecision(4));
    console.log('senior liquidity rate: ', seniorLiquidityRate1.toPrecision(4));
  });

  it('Borrow should return correct interest rate', async function () {
    const seniorDepositAmount = '500000000000000000000';
    const juniorDepositAmount = '100000000000000000000';

    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    await voyager.deposit(tus.address, 1, seniorDepositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());

    await voyager.depositSecurity(owner, tus.address, '100000000000000000000');
    await voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0);

    const poolData = await dp.getPoolData(tus.address);
    console.log('total liquidity: ', poolData.totalLiquidity.toString());

    const juniorLiquidityRate = poolData.juniorLiquidityRate / RAY;
    const seniorLiquidityRate = poolData.seniorLiquidityRate / RAY;
    console.log('junior liquidity rate: ', juniorLiquidityRate.toPrecision(4));
    console.log('senior liquidity rate: ', seniorLiquidityRate.toPrecision(4));
  });
});

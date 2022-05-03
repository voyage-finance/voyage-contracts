const { expect } = require('chai');
const { deployments, ethers, getNamedAccounts } = require('hardhat');
const { BigNumber } = require('ethers');

let owner;
let voyager;
let liquidityManagerProxy;
let juniorDepositToken;
let seniorDepositToken;
let stableDebtToken;
let defaultReserveInterestRateStrategy;
let healthStrategyAddress;
let addressResolver;
let vaultManager;
let tus;
let vm;
let voyageProtocolDataProvider;

describe('Data Provider', function () {
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
    const escrowContract =
      await voyager.getLiquidityManagerEscrowContractAddress();
    // 1000
    await tus.increaseAllowance(escrowContract, '1000000000000000000000');

    const vaultManagerProxy = await ethers.getContract('VaultManagerProxy');
    const VaultManager = await ethers.getContractFactory('VaultManager');
    vm = await VaultManager.attach(vaultManagerProxy.address);

    voyageProtocolDataProvider = await ethers.getContract(
      'VoyageProtocolDataProvider'
    );
  });

  it('Get pool data should return correct value', async function () {
    const reserveLogic = await ethers.getContract('ReserveLogic');
    const LM = await ethers.getContractFactory('LiquidityManager', {
      libraries: { ReserveLogic: reserveLogic.address },
    });
    const lm = await LM.attach(liquidityManagerProxy.address);
    const vaultManagerProxy = await ethers.getContract('VaultManagerProxy');
    const VaultManager = await ethers.getContract('VaultManager');
    const vm = VaultManager.attach(vaultManagerProxy.address);
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
    // 100
    const depositAmount = '100000000000000000000';
    await lm.activeReserve(tus.address);
    await voyager.deposit(tus.address, 1, depositAmount, owner);

    const DataProvider = await ethers.getContractFactory(
      'VoyageProtocolDataProvider'
    );
    const dp = await DataProvider.attach(voyageProtocolDataProvider.address);
    const poolData = await dp.getPoolData(tus.address);
    expect(poolData.seniorLiquidity).to.equal(depositAmount);
  });
});

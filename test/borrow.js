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

describe('Borrow', function () {
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
      '100000000000000000000000000',
      '900000000000000000000000000',
      stableDebtToken.address,
      defaultReserveInterestRateStrategy.address,
      healthStrategyAddress.address
    );
  });

  it('Borrow with wrong vault address should revert', async function () {
    await expect(
      voyager.borrow(tus.address, '10000000000000000000', voyager.address, 0)
    ).to.be.revertedWith('73');
  });

  it('Borrow with no sufficient reserve should revert', async function () {
    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await expect(
      voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0)
    ).to.be.revertedWith('70');
  });

  it('Insufficient credit limit should revert', async function () {
    // deposit sufficient reserve
    const depositAmount = '100000000000000000000';
    await lm.activeReserve(tus.address);
    await voyager.deposit(tus.address, 1, depositAmount, owner);

    await vm.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);
    await expect(
      voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0)
    ).to.be.revertedWith('71');
  });

  it('Sufficient credit limit should return correct value', async function () {
    // deposit sufficient reserve
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
    await vm.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
    await voyager.deposit(tus.address, 0, depositAmount, owner);
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await vm.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);

    // get security deposit escrow address
    const Vault = await ethers.getContractFactory('Vault');
    const escrowAddress = await Vault.attach(
      vaultAddr
    ).getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(escrowAddress, '1000000000000000000000');

    await voyager.depositSecurity(owner, tus.address, '100000000000000000000');
    await voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0);

    const StableDebtToken = await ethers.getContractFactory('StableDebtToken');
    const debtToken = await StableDebtToken.attach(stableDebtToken.address);
    const debtBalance = await debtToken.balanceOf(vaultAddr);
    console.log('debt balance: ', debtBalance);
    // await expect(debtBalance).to.equal(BigNumber.from('10000000000000000000'));
    const vaultBalance = await tus.balanceOf(vaultAddr);
    await expect(vaultBalance).to.equal(BigNumber.from('10000000000000000000'));
    const creditLimit = await voyager.getCreditLimit(owner, tus.address);
    const availableCredit = await voyager.getAvailableCredit(
      owner,
      tus.address
    );
    console.log('credit limit: ', creditLimit.toString());
    console.log('available credit: ', availableCredit.toString());
    await voyager.borrow(tus.address, '10000000000000000000', vaultAddr, '0');
    const vaultBalance2 = await tus.balanceOf(vaultAddr);
    console.log('vault balance: ', vaultBalance2.toString());
    console.log('credit limit: ', creditLimit.toString());
    console.log('available credit: ', availableCredit.toString());
  });
});

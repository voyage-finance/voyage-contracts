const { expect } = require('chai');
const { deployments, ethers, getNamedAccounts } = require('hardhat');
const { BigNumber } = require('ethers');

let owner;
let voyager;
let liquidityManagerProxy;
let liquidityManager;
let loanManager;
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

describe('Repayment', function () {
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
    loanManager = await ethers.getContract('LoanManager');
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

    await tus.increaseAllowance(loanManager.address, '1000000000000000000000');

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
  });

  it('Repay should return correct value', async function () {
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
      stableDebtToken.address,
      defaultReserveInterestRateStrategy.address,
      healthStrategyAddress.address,
      '500000000000000000000000000'
    );
    // 100
    const depositAmount = '100000000000000000000';
    await lm.activeReserve(tus.address);
    await vm.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
    await voyager.deposit(tus.address, 0, depositAmount);
    await voyager.deposit(tus.address, 1, depositAmount);
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
    console.log('debt balance: ', debtBalance.toString());

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine');

    const debtBalanceAfterSevenDays = await debtToken.balanceOf(vaultAddr);
    console.log(
      'debt balance after 7 days: ',
      debtBalanceAfterSevenDays.toString()
    );

    const drawDownNumber = (await debtToken.drawDoneNumber(vaultAddr)) - 1;
    console.log('draw down number: ', drawDownNumber.toString());

    const drawDown = await debtToken.drawDown(
      vaultAddr,
      drawDownNumber.toString()
    );
    console.log('debt amount: ', drawDown.amount.toString());
    await voyager.repay(
      tus.address,
      drawDownNumber,
      '1000000000000000000',
      vaultAddr
    );

    await voyager.repay(
      tus.address,
      drawDownNumber,
      '1000000000000000000',
      vaultAddr
    );

    const drawDownAfter = await debtToken.drawDown(
      vaultAddr,
      drawDownNumber.toString()
    );
    console.log('debt amount after: ', drawDownAfter.amount.toString());

    const repaymentOverall = await debtToken.repaymentOverall(
      vaultAddr,
      drawDownNumber.toString()
    );
    console.log('current total paid: ', repaymentOverall.totalPaid.toString());
    console.log('current tenure: ', repaymentOverall.numPayments.toString());

    const repaymentRecord = await debtToken.repaymentHistory(
      vaultAddr,
      drawDownNumber.toString(),
      repaymentOverall.numPayments - 1
    );
    console.log('repayment record: ', repaymentRecord.toString());
  });
});

import { deployments as d } from 'hardhat';
import { MAX_UINT_256 } from './math';

export const setupDebtTestSuite = d.createFixture(
  async ({ deployments, getNamedAccounts, ethers }) => {
    const { owner, alice, bob } = await getNamedAccounts();
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
      'PriceOracle',
      'LibFinancial',
    ]);
    const liquidityManagerProxy = await ethers.getContract(
      'LiquidityManagerProxy'
    );
    const liquidityManager = await ethers.getContract('LiquidityManager');
    const loanManager = await ethers.getContract('LoanManager');
    const juniorDepositToken = await ethers.getContract('JuniorDepositToken');
    const seniorDepositToken = await ethers.getContract('SeniorDepositToken');
    const stableDebtToken = await ethers.getContract('StableDebtToken');
    const defaultReserveInterestRateStrategy = await ethers.getContract(
      'DefaultReserveInterestRateStrategy'
    );
    const healthStrategyAddress = await ethers.getContract(
      'DefaultHealthStrategy'
    );
    const addressResolver = await ethers.getContract('AddressResolver');
    const tus = await ethers.getContract('Tus');
    const voyager = await ethers.getContract('Voyager');
    const vaultManager = await ethers.getContract('VaultManager');
    const priceOracle = await ethers.getContract('PriceOracle');
    const libFinancial = await ethers.getContract('LibFinancial');

    const decimals = await tus.decimals();
    const multiplier = ethers.BigNumber.from(10).pow(decimals);
    // send some TUS to other accounts for testing
    await deployments.execute(
      'Tus',
      { from: owner, log: true },
      'transfer',
      alice,
      ethers.BigNumber.from(1_000_000).mul(multiplier)
    );
    await deployments.execute(
      'Tus',
      { from: owner, log: true },
      'transfer',
      bob,
      ethers.BigNumber.from(1_000_000).mul(multiplier)
    );

    await voyager.whitelistAddress([owner, alice, bob]);
    await voyager.whitelistFunction([
      ethers.utils.formatBytes32String('createVault'),
      ethers.utils.formatBytes32String('depositSecurity'),
      ethers.utils.formatBytes32String('redeemSecurity'),
      ethers.utils.formatBytes32String('borrow'),
    ]);

    await tus.increaseAllowance(liquidityManager.address, MAX_UINT_256);
    await tus.increaseAllowance(loanManager.address, MAX_UINT_256);

    const vaultManagerProxy = await ethers.getContract('VaultManagerProxy');
    const VaultManager = await ethers.getContractFactory('VaultManager');
    const vm = VaultManager.attach(vaultManagerProxy.address);

    const reserveLogic = await ethers.getContract('ReserveLogic');
    const LM = await ethers.getContractFactory('LiquidityManager', {
      libraries: { ReserveLogic: reserveLogic.address },
    });
    const lm = LM.attach(liquidityManagerProxy.address);
    await lm.initReserve(
      tus.address,
      juniorDepositToken.address,
      seniorDepositToken.address,
      stableDebtToken.address,
      defaultReserveInterestRateStrategy.address,
      healthStrategyAddress.address,
      '500000000000000000000000000'
    );
    await lm.activeReserve(tus.address);

    return {
      owner,
      liquidityManager,
      liquidityManagerProxy,
      loanManager,
      juniorDepositToken,
      seniorDepositToken,
      stableDebtToken,
      defaultReserveInterestRateStrategy,
      healthStrategyAddress,
      addressResolver,
      vaultManager,
      tus,
      vm,
      lm,
      voyager,
      priceOracle,
      libFinancial,
    };
  }
);

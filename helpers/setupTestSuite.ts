import { deployments as d } from 'hardhat';
export const setupTestSuite = d.createFixture(
  async ({ deployments, getNamedAccounts, ethers }) => {
    await deployments.fixture([
      'AddressResolver',
      'Voyager',
      'ACLManager',
      'LiquidityManagerProxy',
      'LiquidityManager',
      'LiquidityManagerStorage',
      'ExtCallAcl',
      'Tokenization',
      'SetAddressResolver',
      'LoanManager',
      'VaultManager',
      'PriceOracle',
      'LibFinancial',
      'VoyageProtocolDataProvider',
    ]);
    const { owner } = await getNamedAccounts();

    const liquidityManagerProxy = await ethers.getContract(
      'LiquidityManagerProxy'
    );
    const liquidityManager = await ethers.getContractAt(
      'LiquidityManager',
      liquidityManagerProxy.address
    );
    const liquidityManagerStorage = await ethers.getContract(
      'LiquidityManagerStorage'
    );
    const loanManager = await ethers.getContract('LoanManager');
    const juniorDepositToken = await ethers.getContract('JuniorDepositToken');
    const seniorDepositToken = await ethers.getContract('SeniorDepositToken');
    const defaultReserveInterestRateStrategy = await ethers.getContract(
      'DefaultReserveInterestRateStrategy'
    );
    const healthStrategyAddress = await ethers.getContract(
      'DefaultHealthStrategy'
    );
    const addressResolver = await ethers.getContract('AddressResolver');
    const aclManager = await ethers.getContract('ACLManager');
    const tus = await ethers.getContract('Tus');
    const voyager = await ethers.getContract('Voyager');
    const vaultManagerProxy = await ethers.getContract('VaultManagerProxy');
    const vaultManager = await ethers.getContractAt(
      'VaultManager',
      vaultManagerProxy.address
    );
    const vaultStorage = await ethers.getContract('VaultStorage');

    const extCallACLProxy = await ethers.getContract('ExtCallACLProxy');
    const extCallACL = await ethers.getContractAt(
      'ExtCallACL',
      extCallACLProxy.address
    );

    const priceOracle = await ethers.getContract('PriceOracle');
    const libFinancial = await ethers.getContract('LibFinancial');
    const voyageProtocolDataProvider = await ethers.getContract(
      'VoyageProtocolDataProvider'
    );

    await aclManager.grantLiquidityManager(owner);
    await aclManager.grantVaultManager(owner);
    await aclManager.grantPoolManager(owner);
    await aclManager.grantVaultManagerContract(vaultManager.address);

    const names = [
      ethers.utils.formatBytes32String('voyager'),
      ethers.utils.formatBytes32String('liquidityManagerProxy'),
      ethers.utils.formatBytes32String('liquidityManagerStorage'),
      ethers.utils.formatBytes32String('aclManager'),
      ethers.utils.formatBytes32String('extCallACLProxy'),
      ethers.utils.formatBytes32String('vaultManagerProxy'),
      ethers.utils.formatBytes32String('vaultStorage'),
    ];
    const destinations = [
      voyager.address,
      liquidityManagerProxy.address,
      liquidityManagerStorage.address,
      aclManager.address,
      extCallACLProxy.address,
      vaultManagerProxy.address,
      vaultStorage.address,
    ];

    await addressResolver.importAddresses(names, destinations);

    await voyager.whitelistAddress([owner]);
    await voyager.whitelistFunction([
      ethers.utils.formatBytes32String('createVault'),
      ethers.utils.formatBytes32String('depositSecurity'),
      ethers.utils.formatBytes32String('redeemSecurity'),
    ]);

    return {
      owner,
      liquidityManager,
      extCallACL,
      tus,
      vaultManager,
      vaultStorage,
      voyager,
      voyageProtocolDataProvider,
    };
  }
);

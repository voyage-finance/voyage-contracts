import { deployments as d } from 'hardhat';
import { MAX_UINT_256 } from './math';
export const setupTestSuite = d.createFixture(
  async ({ deployments, getNamedAccounts, ethers }) => {
    await deployments.fixture([
      'AddressResolver',
      'Voyager',
      'ACLManager',
      'ExtCallAcl',
      'Tokenization',
      'SetAddressResolver',
      'VaultManager',
      'PriceOracle',
      'LibFinancial',
    ]);
    const { owner } = await getNamedAccounts();

    /* --------------------------------- voyager -------------------------------- */
    const voyager = await ethers.getContract('Voyager');
    await voyager.whitelistAddress([owner]);
    await voyager.whitelistFunction([
      ethers.utils.formatBytes32String('createVault'),
      ethers.utils.formatBytes32String('depositSecurity'),
      ethers.utils.formatBytes32String('redeemSecurity'),
    ]);

    /* ---------------------------- vault management ---------------------------- */
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

    /* ---------------------------------- infra --------------------------------- */
    const aclManager = await ethers.getContract('ACLManager');
    await aclManager.grantLiquidityManager(owner);
    await aclManager.grantVaultManager(owner);
    await aclManager.grantPoolManager(owner);
    await aclManager.grantVaultManagerContract(vaultManager.address);

    const priceOracle = await ethers.getContract('PriceOracle');
    // TODO: deploy this in a separate libraries script
    // const libFinancial = await ethers.getContract('LibFinancial');

    const addressResolver = await ethers.getContract('AddressResolver');
    const names = [
      ethers.utils.formatBytes32String('voyager'),
      ethers.utils.formatBytes32String('aclManager'),
      ethers.utils.formatBytes32String('extCallACLProxy'),
      ethers.utils.formatBytes32String('vaultManagerProxy'),
      ethers.utils.formatBytes32String('vaultStorage'),
    ];
    const destinations = [
      voyager.address,
      aclManager.address,
      extCallACLProxy.address,
      vaultManagerProxy.address,
      vaultStorage.address,
    ];
    await addressResolver.importAddresses(names, destinations);

    /* ------------------------------ tokenization ------------------------------ */
    const juniorDepositToken = await ethers.getContract('JuniorDepositToken');
    const seniorDepositToken = await ethers.getContract('SeniorDepositToken');
    const tus = await ethers.getContract('Tus');
    const defaultReserveInterestRateStrategy = await ethers.getContract(
      'DefaultReserveInterestRateStrategy'
    );
    const defaultLoanStrategy = await ethers.getContract('DefaultLoanStrategy');
    const healthStrategy = await ethers.getContract('DefaultHealthStrategy');

    await voyager.initReserve(
      tus.address,
      juniorDepositToken.address,
      seniorDepositToken.address,
      defaultReserveInterestRateStrategy.address,
      healthStrategy.address,
      defaultLoanStrategy.address,
      '500000000000000000000000000'
    );
    // 100
    await voyager.activateReserve(tus.address);
    await tus.approve(voyager.address, MAX_UINT_256);

    return {
      owner,
      healthStrategy,
      defaultLoanStrategy,
      defaultReserveInterestRateStrategy,
      extCallACL,
      tus,
      juniorDepositToken,
      seniorDepositToken,
      vaultManager,
      vaultStorage,
      voyager,
    };
  }
);

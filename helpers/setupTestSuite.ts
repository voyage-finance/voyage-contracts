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

    /* ---------------------------- vault management ---------------------------- */
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

    const priceOracle = await ethers.getContract('PriceOracle');
    // TODO: deploy this in a separate libraries script
    // const libFinancial = await ethers.getContract('LibFinancial');

    const addressResolver = await ethers.getContract('AddressResolver');
    const names = [
      ethers.utils.formatBytes32String('voyager'),
      ethers.utils.formatBytes32String('aclManager'),
      ethers.utils.formatBytes32String('extCallACLProxy'),
    ];
    const destinations = [
      voyager.address,
      aclManager.address,
      extCallACLProxy.address,
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

    /* ------------------------- reserve initialisation ------------------------- */
    await voyager.initReserve(
      tus.address,
      juniorDepositToken.address,
      seniorDepositToken.address,
      defaultReserveInterestRateStrategy.address,
      healthStrategy.address,
      defaultLoanStrategy.address,
      '500000000000000000000000000'
    );
    await voyager.activateReserve(tus.address);
    await tus.approve(voyager.address, MAX_UINT_256);

    /* -------------------------- vault initialisation -------------------------- */
    await voyager.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
    await voyager.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(salt);
    const vaultAddr = await voyager.getVault(owner);
    console.log('vault address: ', vaultAddr);
    await voyager.initVault(vaultAddr, tus.address);

    // get security deposit escrow address
    const vault = await ethers.getContractAt('Vault', vaultAddr);
    const escrowAddress = await vault.getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(escrowAddress, MAX_UINT_256);

    return {
      owner,
      healthStrategy,
      defaultLoanStrategy,
      defaultReserveInterestRateStrategy,
      extCallACL,
      tus,
      juniorDepositToken,
      seniorDepositToken,
      vault,
      voyager,
    };
  }
);

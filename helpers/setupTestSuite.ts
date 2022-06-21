import { deployments as d } from 'hardhat';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ERC20 } from '../typechain/ERC20';
import { Voyager } from '../typechain/Voyager';
import { deployFacets, FacetCutAction } from './diamond';
import { decimals, MAX_UINT_256 } from './math';

const dec = decimals(18);

const setupBase = async ({
  deployments,
  getNamedAccounts,
  ethers,
}: HardhatRuntimeEnvironment) => {
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
  const { owner, alice, bob } = await getNamedAccounts();

  /* --------------------------------- voyager -------------------------------- */
  const voyager = await ethers.getContract<Voyager>('Voyager');

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
  const libFinancial = await ethers.getContract('LibFinancial');
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

  /* ------------------------- reserve initialisation ------------------------- */
  await voyager.initReserve(
    tus.address,
    juniorDepositToken.address,
    seniorDepositToken.address,
    defaultReserveInterestRateStrategy.address,
    defaultLoanStrategy.address,
    '500000000000000000000000000'
  );
  await voyager.activateReserve(tus.address);
  await tus.approve(voyager.address, MAX_UINT_256);

  /* -------------------------- vault initialisation -------------------------- */
  await voyager.setMaxMargin(tus.address, '1000000000000000000000');
  await voyager.setMarginRequirement(
    tus.address,
    '100000000000000000000000000'
  ); // 0.1

  // create an empty vault
  await voyager.createVault(owner, tus.address);
  const vaultAddr = await voyager.getVault(owner);
  console.log('vault address: ', vaultAddr);

  // get security deposit escrow address
  const vault = await ethers.getContractAt('Vault', vaultAddr);
  const escrowAddress = await vault.getMarginEscrowAddress();
  await tus.approve(escrowAddress, MAX_UINT_256);

  return {
    owner,
    alice,
    bob,
    defaultLoanStrategy,
    defaultReserveInterestRateStrategy,
    libFinancial,
    priceOracle,
    extCallACL,
    tus,
    juniorDepositToken,
    seniorDepositToken,
    vault,
    voyager,
  };
};

const setupMocks = async (
  { ethers, deployments, getNamedAccounts }: HardhatRuntimeEnvironment,
  args: any = {}
) => {
  const { owner } = await getNamedAccounts();
  const [facets] = await deployFacets({
    name: 'MockLoanFacet',
    from: owner,
    log: true,
  });
  await deployments.deploy('TestInitDiamond', {
    from: owner,
    log: true,
    args: [],
  });
  const { principalBalance = 0, interestBalance = 0 } = args;
  const initDiamond = await ethers.getContract('TestInitDiamond');
  const initArgs = initDiamond.interface.encodeFunctionData('init', [
    {
      principalBalance: ethers.BigNumber.from(principalBalance).mul(dec),
      interestBalance: ethers.BigNumber.from(interestBalance).mul(dec),
    },
  ]);

  await deployments.execute(
    'Voyager',
    { from: owner, log: true },
    'diamondCut',
    [{ ...facets[0], action: FacetCutAction.Replace }],
    initDiamond.address,
    initArgs
  );
};

export const setupTestSuite = d.createFixture(async (hre) => {
  return setupBase(hre);
});

export const setupTestSuiteWithMocks = d.createFixture(async (hre, args) => {
  const base = await setupBase(hre);
  await setupMocks(hre, args);
  const voyager = await hre.ethers.getContract<Voyager>('Voyager');
  return {
    ...base,
    underlying: base.tus as ERC20,
    decimals: dec,
    voyager,
  };
});

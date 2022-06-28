import BigNumber from 'bignumber.js';
import { deployments as d } from 'hardhat';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ERC20 } from '../typechain/ERC20';
import { Voyager } from '../typechain/Voyager';
import { deployFacets, FacetCutAction } from './diamond';
import { decimals, MAX_UINT_256, toRay } from './math';

const dec = decimals(18);

const setupBase = async ({
  deployments,
  getNamedAccounts,
  ethers,
}: HardhatRuntimeEnvironment) => {
  await deployments.fixture([
    'Voyager',
    'Tokenization',
    'VaultManager',
    'PriceOracle',
  ]);
  const { owner, alice, bob } = await getNamedAccounts();

  /* --------------------------------- voyager -------------------------------- */
  const voyager = await ethers.getContract<Voyager>('Voyager');

  /* ---------------------------------- infra --------------------------------- */
  const priceOracle = await ethers.getContract('PriceOracle');
  /* ------------------------------ tokenization ------------------------------ */
  const tus = await ethers.getContract('Tus');
  const crab = await ethers.getContract('Crab');
  const marketPlace = await ethers.getContract('MockMarketPlace');
  const defaultReserveInterestRateStrategy = await ethers.getContract(
    'DefaultReserveInterestRateStrategy'
  );
  const defaultLoanStrategy = await ethers.getContract('DefaultLoanStrategy');

  /* ------------------------- reserve initialisation ------------------------- */
  await voyager.initReserve(
    tus.address,
    defaultReserveInterestRateStrategy.address,
    defaultLoanStrategy.address,
    '500000000000000000000000000',
    priceOracle.address
  );
  await voyager.activateReserve(tus.address);
  const [senior, junior] = await voyager.getDepositTokens(tus.address);
  const seniorDepositToken = await ethers.getContractAt(
    'SeniorDepositToken',
    senior
  );
  const juniorDepositToken = await ethers.getContractAt(
    'JuniorDepositToken',
    junior
  );
  await tus.approve(voyager.address, MAX_UINT_256);

  /* -------------------------- vault initialisation -------------------------- */
  await voyager.setMaxMargin(tus.address, '1000000000000000000000');
  const marginRequirement = toRay(new BigNumber('0.1')).toFixed();
  await voyager.setMarginRequirement(tus.address, marginRequirement); // 0.1

  // create an empty vault
  await voyager.createVault(owner);
  const vaultAddr = await voyager.getVault(owner);
  const vault = await ethers.getContractAt('Vault', vaultAddr);
  await voyager.initAsset(vaultAddr, tus.address);
  await tus.approve(vault.address, MAX_UINT_256);

  return {
    owner,
    alice,
    bob,
    defaultLoanStrategy,
    defaultReserveInterestRateStrategy,
    priceOracle,
    tus,
    crab,
    marketPlace,
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

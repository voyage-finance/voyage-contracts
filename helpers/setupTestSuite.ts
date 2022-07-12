import BigNumber from 'bignumber.js';
import { deployments as d } from 'hardhat';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ERC20 } from '../typechain/ERC20';
import { Vault } from '../typechain/Vault';
import { Voyage } from '../typechain/Voyage';
import { deployFacets, FacetCutAction } from './diamond';
import { decimals, MAX_UINT_256, toRay } from './math';

const dec = decimals(18);

const setupBase = async ({
  deployments,
  getNamedAccounts,
  ethers,
}: HardhatRuntimeEnvironment) => {
  await deployments.fixture(['Voyage', 'Vault', 'Tokenization']);
  const { owner, alice, bob } = await getNamedAccounts();

  /* --------------------------------- voyage -------------------------------- */
  const voyage = await ethers.getContract<Voyage>('Voyage');

  /* ---------------------------------- infra --------------------------------- */
  const priceOracle = await ethers.getContract('PriceOracle');
  /* ------------------------------ tokenization ------------------------------ */
  const tus = await ethers.getContract('Tus');
  const crab = await ethers.getContract('Crab');
  const marketPlace = await ethers.getContract('MockMarketPlace');
  const battleGame = await ethers.getContract('MockCrabadaBattleGame');
  const defaultReserveInterestRateStrategy = await ethers.getContract(
    'DefaultReserveInterestRateStrategy'
  );
  const defaultLoanStrategy = await ethers.getContract('DefaultLoanStrategy');
  console.log('default loan straategy: ', defaultLoanStrategy.address);

  /* ------------------------- reserve initialisation ------------------------- */
  await voyage.initReserve(
    tus.address,
    defaultReserveInterestRateStrategy.address,
    defaultLoanStrategy.address,
    '500000000000000000000000000',
    priceOracle.address,
    crab.address
  );
  await voyage.activateReserve(tus.address);
  const cutRatio = toRay(new BigNumber('0.2')).toFixed();
  await voyage.updateProtocolFee(owner, cutRatio);
  const [senior, junior] = await voyage.getDepositTokens(tus.address);
  const seniorDepositToken = await ethers.getContractAt(
    'SeniorDepositToken',
    senior
  );
  const juniorDepositToken = await ethers.getContractAt(
    'JuniorDepositToken',
    junior
  );
  await tus.approve(voyage.address, MAX_UINT_256);

  /* -------------------------- vault initialisation -------------------------- */
  await voyage.setMaxMargin(tus.address, '1000000000000000000000');
  const marginRequirement = toRay(new BigNumber('0.1')).toFixed();
  await voyage.setMarginRequirement(tus.address, marginRequirement); // 0.1

  // create an empty vault
  const salt = ethers.utils.formatBytes32String(
    (Math.random() + 1).toString(36).substring(7)
  );
  await voyage.createVault(owner, salt);
  const deployedVault = await voyage.getVault(owner);
  await tus.approve(deployedVault, MAX_UINT_256);
  const vault = await ethers.getContractAt<Vault>(
    'hardhat-diamond-abi/HardhatDiamondABI.sol:Vault',
    deployedVault
  );
  await voyage.initAsset(deployedVault, tus.address);

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
    battleGame,
    juniorDepositToken,
    seniorDepositToken,
    vault,
    voyage,
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
    'Voyage',
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
  const voyage = await hre.ethers.getContract<Voyage>('Voyage');
  return {
    ...base,
    underlying: base.tus as ERC20,
    decimals: dec,
    voyage,
  };
});

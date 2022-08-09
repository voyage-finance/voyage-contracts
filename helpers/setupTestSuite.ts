import BigNumber from 'bignumber.js';
import { deployments as d } from 'hardhat';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ERC20 } from '../typechain/ERC20';
import { Voyage } from '../typechain/Voyage';
import { deployFacets, FacetCutAction } from './diamond';
import { decimals, MAX_UINT_256, toRay, toWad } from './math';
import { randomBytes } from 'crypto';
import './wadraymath';

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
  /* ---------------------------------- adapter --------------------------------- */
  const looksRareAdapter = await ethers.getContract('LooksRareAdapter');
  /* ------------------------------ tokenization ------------------------------ */
  const tus = await ethers.getContract('Tus');
  const crab = await ethers.getContract('Crab');
  const marketPlace = await ethers.getContract('MockMarketPlace');
  const defaultReserveInterestRateStrategy = await ethers.getContract(
    'DefaultReserveInterestRateStrategy'
  );
  /* ------------------------- reserve initialisation ------------------------- */
  await voyage.initReserve(
    crab.address,
    tus.address,
    defaultReserveInterestRateStrategy.address,
    priceOracle.address
  );
  // 105%
  await voyage.setLiquidationBonus(crab.address, 10500);
  await voyage.setIncomeRatio(crab.address, 0.5 * 1e4);
  await voyage.setLoanParams(crab.address, 30, 90, 10);
  await voyage.activateReserve(crab.address);
  const cutRatio = toRay(new BigNumber('0.2')).toFixed();
  await voyage.updateProtocolFee(owner, cutRatio);
  await voyage.updateMarketPlaceData(
    marketPlace.address,
    looksRareAdapter.address
  );
  const [senior, junior] = await voyage.getDepositTokens(crab.address);
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

  // create an empty vault
  const salt = randomBytes(20);
  await voyage.createVault(owner, salt);
  const deployedVault = await voyage.getVault(owner);
  await tus.approve(deployedVault, MAX_UINT_256);
  const abiCoder = ethers.utils.defaultAbiCoder;
  const makerOrderData = abiCoder.encode(
    [
      'bool',
      'address',
      'address',
      'uint256',
      'uint256',
      'uint256',
      'address',
      'address',
      'uint256',
      'uint256',
      'uint256',
      'uint256',
      'bytes',
      'uint8',
      'bytes32',
      'bytes32',
    ],
    [
      true,
      owner,
      crab.address,
      1000,
      1,
      1,
      alice,
      tus.address,
      1,
      1,
      1,
      1,
      ethers.utils.arrayify('0x1234'),
      1,
      ethers.utils.arrayify(
        '0x66fdd5e25ef9ddb305ba3c2aae1856ab9c6f2979000000000000000000000000'
      ),
      ethers.utils.arrayify(
        '0x66fdd5e25ef9ddb305ba3c2aae1856ab9c6f2979000000000000000000000000'
      ),
    ]
  );
  const floorPrice = toWad(10);
  const takerOrderData = abiCoder.encode(
    ['bool', 'address', 'uint256', 'uint256', 'uint256', 'bytes'],
    [
      true,
      deployedVault,
      floorPrice,
      1,
      1,
      ethers.utils.arrayify(
        '0x66fdd5e25ef9ddb305ba3c2aae1856ab9c6f2979000000000000000000000000'
      ),
    ]
  );
  var abi = [
    'function matchAskWithTakerBidUsingETHAndWETH((bool,address,uint256,uint256,uint256,bytes),(bool,address,address,uint256,uint256,uint256,address,address,uint256,uint256,uint256,uint256,bytes,uint8,bytes32,bytes32))',
  ];
  var iface = new ethers.utils.Interface(abi);
  var selector = iface.getSighash('matchAskWithTakerBidUsingETHAndWETH');
  const purchaseData = abiCoder.encode(
    ['address', 'bytes4', 'bytes', 'bytes'],
    [marketPlace.address, selector, makerOrderData, takerOrderData]
  );

  return {
    owner,
    alice,
    bob,
    defaultReserveInterestRateStrategy,
    priceOracle,
    tus,
    crab,
    marketPlace,
    juniorDepositToken,
    seniorDepositToken,
    deployedVault,
    voyage,
    purchaseData,
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

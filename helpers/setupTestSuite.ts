import { Voyage, VoyagePaymaster, WETH9 } from '@contracts';
import {
  LooksRareExchangeAbi,
  MakerOrderWithVRS,
  TakerOrderWithEncodedParams,
} from '@looksrare/sdk';
import { SeaportABI } from '@opensea/seaport-js/lib/abi/Seaport';
import {
  BasicOrderParametersStruct,
  Seaport,
} from '@opensea/seaport-js/lib/typechain/Seaport';
import { BigNumber } from 'ethers';
import { deployments as d } from 'hardhat';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployFacets, FacetCutAction } from './diamond';
import { decimals, MAX_UINT_256, toWad } from './math';
import { setHRE } from './task-helpers/hre';
import './wadraymath';

const dec = decimals(18);

interface ReserveConfiguration {
  liquidationBonus: number;
  incomeRatio: number;
  optimalLiquidityRatio: number;
  epoch: number;
  term: number;
  gracePeriod: number;
  protocolFee: number;
  maxStaleness: number;
}

const setupBase = async (hre: HardhatRuntimeEnvironment) => {
  setHRE(hre);
  const { deployments, getNamedAccounts, ethers } = hre;
  await deployments.fixture([
    'Mocks',
    'VToken',
    'Vault',
    'Adapters',
    'InterestRateStrategy',
    'Oracle',
    'Diamond',
    'Facets',
    'Paymaster',
  ]);
  const { owner, alice, bob, forwarder, treasury } = await getNamedAccounts();

  /* --------------------------------- voyage -------------------------------- */
  const voyage = await ethers.getContract<Voyage>('Voyage');
  /* ---------------------------------- infra --------------------------------- */
  const paymaster = await ethers.getContract<VoyagePaymaster>(
    'VoyagePaymaster'
  );
  await paymaster.setTrustedForwarder(forwarder);
  const priceOracle = await ethers.getContract('PriceOracle');
  const weth = await ethers.getContract<WETH9>('WETH9');
  await weth.deposit({ value: ethers.utils.parseEther('10000000') });
  await voyage.setGSNConfiguration(paymaster.address, forwarder);
  /* ---------------------------------- adapter --------------------------------- */
  const looksRareAdapter = await ethers.getContract('LooksRareAdapter');
  const seaportAdapter = await ethers.getContract('SeaportAdapter');
  /* ------------------------------ tokenization ------------------------------ */
  const crab = await ethers.getContract('Crab');
  const marketPlace = await ethers.getContract('MockMarketPlace');
  const seaport = await ethers.getContract('MockSeaport');
  const defaultReserveInterestRateStrategy = await ethers.getContract(
    'DefaultReserveInterestRateStrategy'
  );
  /* ------------------------- reserve initialisation ------------------------- */
  const reserveConfiguration: ReserveConfiguration = {
    liquidationBonus: 10500,
    incomeRatio: 0.5 * 1e4,
    optimalLiquidityRatio: 0.5 * 1e4,
    epoch: 30,
    term: 90,
    gracePeriod: 10,
    protocolFee: 200,
    maxStaleness: 10000,
  };

  await voyage.initReserve(
    crab.address,
    weth.address,
    defaultReserveInterestRateStrategy.address,
    priceOracle.address
  );
  // 105%
  await voyage.setLiquidationBonus(
    crab.address,
    reserveConfiguration.liquidationBonus
  );
  await voyage.setIncomeRatio(crab.address, reserveConfiguration.incomeRatio);
  await voyage.setOptimalLiquidityRatio(
    crab.address,
    reserveConfiguration.optimalLiquidityRatio
  );
  await voyage.setLoanParams(
    crab.address,
    reserveConfiguration.epoch,
    reserveConfiguration.term,
    reserveConfiguration.gracePeriod
  );
  await voyage.activateReserve(crab.address);
  await voyage.setMaxTwapStaleness(
    crab.address,
    reserveConfiguration.maxStaleness
  );
  await voyage.updateProtocolFee(treasury, reserveConfiguration.protocolFee);
  await voyage.updateMarketPlaceData(
    marketPlace.address,
    looksRareAdapter.address
  );
  await voyage.updateMarketPlaceData(seaport.address, seaportAdapter.address);
  const [senior, junior] = await voyage.getDepositTokens(crab.address);
  const seniorDepositToken = await ethers.getContractAt(
    'SeniorDepositToken',
    senior
  );
  const juniorDepositToken = await ethers.getContractAt(
    'JuniorDepositToken',
    junior
  );
  await weth.approve(voyage.address, MAX_UINT_256);
  /* -------------------------- vault initialisation -------------------------- */

  // create an empty vault
  const salt = ethers.utils.toUtf8Bytes('hw.kk@voyage.finance').slice(0, 42);
  await voyage.createVault(owner, salt);
  const deployedVault = await voyage.getVault(owner);
  // fund vault for first payment
  const tx = {
    to: deployedVault,
    value: ethers.utils.parseEther('100'),
  };
  const ownerSigner = await ethers.getSigner(owner);
  const createReceipt = await ownerSigner.sendTransaction(tx);
  await createReceipt.wait();
  await weth.transfer(deployedVault, toWad(10));
  await weth.approve(deployedVault, MAX_UINT_256);

  /// todo delete
  var input =
    '5369676e61747572653a20496e76616c69640000000000000000000000000000';

  const output = Buffer.from(input, 'hex');
  console.log(input + ' -> ' + output);

  const provider = new ethers.providers.AlchemyProvider(
    'rinkeby',
    process.env.RINKEBY_API_KEY
  );
  const LOOKS_EXCHANGE_RINKEBY = '0x1AA777972073Ff66DCFDeD85749bDD555C0665dA';
  const looks = new ethers.Contract(
    LOOKS_EXCHANGE_RINKEBY,
    LooksRareExchangeAbi,
    provider
  );
  const looksRareMakerOrderData: MakerOrderWithVRS = {
    isOrderAsk: true,
    signer: '0xAc786F3E609eeBC3830A26881bd026B6b9211ae2',
    collection: '0xd10E39Afe133eF729aE7f4266B26d173BC5AD1B1',
    price: toWad(10),
    tokenId: '1',
    amount: 1,
    strategy: '0x732319A3590E4fA838C111826f9584a9A2fDEa1a',
    currency: '0xc778417E063141139Fce010982780140Aa0cD5Ab',
    nonce: ethers.constants.Zero,
    startTime: 1661852317,
    endTime: 1662457076,
    minPercentageToAsk: 9800,
    params: ethers.utils.defaultAbiCoder.encode([], []),
    v: 27,
    r: '0x66f2bf329cf885420596359ed1b435ef3ffe3b35efcbf10854b393724482369b',
    s: '0x6db5028edf4f90eba89576e8181a4b4051ae9053b08b0dfb5c0fd6c580b73f66',
  };
  const looksRareTakerOrderData: TakerOrderWithEncodedParams = {
    isOrderAsk: false,
    taker: deployedVault,
    price: looksRareMakerOrderData.price,
    tokenId: looksRareMakerOrderData.tokenId,
    minPercentageToAsk: 9800,
    params: ethers.utils.defaultAbiCoder.encode([], []),
  };
  const purchaseDataFromLooksRare = (
    await looks.populateTransaction.matchAskWithTakerBidUsingETHAndWETH(
      looksRareTakerOrderData,
      looksRareMakerOrderData
    )
  ).data!;
  const seaportInstance: Seaport = new ethers.Contract(
    ethers.constants.AddressZero,
    SeaportABI,
    provider
  ) as Seaport;
  const basicOrder: BasicOrderParametersStruct = {
    considerationToken: ethers.constants.AddressZero,
    considerationIdentifier: ethers.BigNumber.from(0),
    considerationAmount: ethers.BigNumber.from(1),
    offerer: owner,
    offerToken: '0xBd3531dA5CF5857e7CfAA92426877b022e612cf8',
    offerIdentifier: ethers.BigNumber.from(6532),
    offerAmount: BigNumber.from(1),
    zone: '0x004C00500000aD104D7DBd00e3ae0A5C00560C00',
    basicOrderType: ethers.BigNumber.from(2),
    startTime: ethers.BigNumber.from('1662539571'),
    endTime: ethers.BigNumber.from('1662798771'),
    zoneHash:
      '0x0000000000000000000000000000000000000000000000000000000000000000',
    salt: ethers.BigNumber.from('21338839425849832'),
    offererConduitKey:
      '0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000',
    fulfillerConduitKey:
      '0x0000000000000000000000000000000000000000000000000000000000000000',
    totalOriginalAdditionalRecipients: ethers.BigNumber.from(0),
    additionalRecipients: [],
    signature:
      '0xaf15a1ecaf46d57aea6e14bbba1e5a2f3714e42a961c7668fd8c35bafb5ea4885f4c82f2eb7d7cf7125b61564931763c82877cdb67cb0f875d9d3449d71e53c71b',
  };
  const purchaseDataFromOpensea = (
    await seaportInstance.populateTransaction.fulfillBasicOrder(basicOrder)
  ).data!;
  // send the vault some ETH
  const weth9 = await ethers.getContract<WETH9>('WETH9');
  const signer = await ethers.getSigner(owner);
  await signer.sendTransaction({
    to: deployedVault,
    value: ethers.BigNumber.from('100000000000000000'),
  });
  await weth9.deposit({
    value: ethers.BigNumber.from('100000000000000000'),
  });
  await weth9.transfer(
    deployedVault,
    ethers.BigNumber.from('100000000000000000')
  );

  return {
    owner,
    alice,
    bob,
    forwarder,
    treasury,
    defaultReserveInterestRateStrategy,
    priceOracle,
    paymaster,
    crab,
    marketPlace,
    seaport,
    juniorDepositToken,
    seniorDepositToken,
    deployedVault,
    voyage,
    purchaseDataFromLooksRare,
    purchaseDataFromOpensea,
    weth,
    reserveConfiguration,
  };
};

const setupMocks = async (
  { ethers, deployments, getNamedAccounts }: HardhatRuntimeEnvironment,
  args: any = {}
) => {
  const { owner } = await getNamedAccounts();
  const [facets] = await deployFacets(
    {
      name: 'MockLoanFacet',
      from: owner,
      log: true,
    },
    {
      name: 'MockContextFacet',
      from: owner,
      log: true,
    }
  );
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
    [
      { ...facets[0], action: FacetCutAction.Replace },
      { ...facets[1], action: FacetCutAction.Add },
    ],
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
    underlying: base.weth,
    decimals: dec,
    voyage,
  };
});

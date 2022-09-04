import { deployments as d } from 'hardhat';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { VoyagePaymaster } from 'typechain/VoyagePaymaster';
import { WETH9 } from 'typechain/WETH9';
import { Voyage } from '../typechain/Voyage';
import { deployFacets, FacetCutAction } from './diamond';
import { decimals, MAX_UINT_256, toWad } from './math';
import './wadraymath';
import {
  LooksRareExchangeAbi,
  MakerOrderWithVRS,
  TakerOrderWithEncodedParams,
} from '@looksrare/sdk';

const dec = decimals(18);

const setupBase = async ({
  deployments,
  getNamedAccounts,
  ethers,
}: HardhatRuntimeEnvironment) => {
  await deployments.fixture(['Voyage', 'Vault', 'Tokenization']);
  const { owner, alice, bob, treasury, forwarder } = await getNamedAccounts();

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
  await voyage.initReserve(
    crab.address,
    weth.address,
    defaultReserveInterestRateStrategy.address,
    priceOracle.address
  );
  // 105%
  await voyage.setLiquidationBonus(crab.address, 10500);
  await voyage.setIncomeRatio(crab.address, 0.5 * 1e4);
  await voyage.setOptimalLiquidityRatio(crab.address, 0.5 * 1e4);
  await voyage.setLoanParams(crab.address, 30, 90, 10);
  await voyage.activateReserve(crab.address);
  const cutPercentage = '200'; //2%
  await voyage.updateProtocolFee(owner, cutPercentage);
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
  const abiCoder = ethers.utils.defaultAbiCoder;

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
  const basicOrderParameters = abiCoder.encode(
    [
      'address',
      'uint256',
      'uint256',
      'address',
      'address',
      'address',
      'uint256',
      'uint256',
      'uint8',
      'uint256',
      'uint256',
      'bytes32',
      'uint256',
      'bytes32',
      'bytes32',
      'uint256',
      'tuple(uint256 amount,address recipient)[]',
      'bytes',
    ],
    [
      '0x0000000000000000000000000000000000000000',
      1,
      1,
      owner,
      owner,
      weth.address,
      1,
      1,
      1,
      1,
      1,
      ethers.utils.arrayify(
        '0x66fdd5e25ef9ddb305ba3c2aae1856ab9c6f2979000000000000000000000000'
      ),
      1,
      ethers.utils.arrayify(
        '0x66fdd5e25ef9ddb305ba3c2aae1856ab9c6f2979000000000000000000000000'
      ),
      ethers.utils.arrayify(
        '0x66fdd5e25ef9ddb305ba3c2aae1856ab9c6f2979000000000000000000000000'
      ),
      1,
      [{ amount: toWad(1), recipient: owner }],
      ethers.utils.arrayify('0x1234'),
    ]
  );
  const purchaseDataFromOpensea = abiCoder.encode(
    ['address', 'address', 'bytes4', 'bytes'],
    [deployedVault, seaport.address, '0xfb0f3ee1', basicOrderParameters]
  );
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

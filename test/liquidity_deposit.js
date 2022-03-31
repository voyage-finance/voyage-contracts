const { expect } = require('chai');
const { BigNumber } = require('ethers');

let owner;
let voyager;
let tus;
let escrowContract;
let juniorDepositToken;
let seniorDepositToken;

describe('Reserve Deposit', function () {
  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    // deploy Voyager contract
    const Voyager = await ethers.getContractFactory('Voyager');
    voyager = await Voyager.deploy(owner.address);

    // deploy AddressResolver contract
    const AddressResolver = await ethers.getContractFactory('AddressResolver');
    const addressResolver = await AddressResolver.deploy();

    // set AddressResolver address to Voyager
    await voyager.setAddressResolverAddress(addressResolver.address);

    // deploy LiquidityManagerProxy contract
    const LiquidityManagerProxy = await ethers.getContractFactory(
      'LiquidityManagerProxy'
    );
    const liquidityManagerProxy = await LiquidityManagerProxy.deploy();

    // deploy LiquidityManager contract
    const LiquidityManager = await ethers.getContractFactory(
      'LiquidityManager'
    );
    const liquidityManager = await LiquidityManager.deploy(
      liquidityManagerProxy.address,
      voyager.address
    );
    liquidityManagerProxy.setTarget(liquidityManager.address);

    // deploy ReserveLogic library
    const ReserveLogic = await ethers.getContractFactory('ReserveLogic');
    const reserveLogic = await ReserveLogic.deploy();
    // deploy ValidationLogic library
    const ValidationLogic = await ethers.getContractFactory('ValidationLogic');
    const validationLogic = await ValidationLogic.deploy();

    // deploy LiquidityManagerStorage contract
    const LiquidityManagerStorage = await ethers.getContractFactory(
      'LiquidityManagerStorage',
      {
        libraries: {
          ReserveLogic: reserveLogic.address,
          ValidationLogic: validationLogic.address,
        },
      }
    );
    const liquidityManagerStorage = await LiquidityManagerStorage.deploy(
      liquidityManager.address
    );

    // import vaultManager to AddressResolver
    const names = [
      ethers.utils.formatBytes32String('liquidityManagerProxy'),
      ethers.utils.formatBytes32String('liquidityManager'),
      ethers.utils.formatBytes32String('liquidityManagerStorage'),
    ];
    const destinations = [
      liquidityManagerProxy.address,
      liquidityManager.address,
      liquidityManagerStorage.address,
    ];

    await addressResolver.importAddresses(names, destinations);

    await liquidityManagerProxy.transferOwnership(voyager.address);
    await voyager.claimLiquidityManagerProxyOwnership();

    /******************************** init reserve ********************************/
    const wad = 1000000000000000000;
    const ray = 1000000000000000000000000000;

    // deploy Tus
    const Tus = await ethers.getContractFactory('Tus');
    tus = await Tus.deploy(BigInt(1000) * BigInt(wad));

    // deploy junior deposit token
    const JuniorDepositToken = await ethers.getContractFactory(
      'JuniorDepositToken'
    );
    juniorDepositToken = await JuniorDepositToken.deploy();

    await juniorDepositToken.initialize(
      addressResolver.address,
      tus.address,
      tus.decimals(),
      tus.name(),
      tus.symbol(),
      ethers.utils.formatBytes32String('')
    );

    // deploy senior deposit token
    const SeniorDepositToken = await ethers.getContractFactory(
      'SeniorDepositToken'
    );
    seniorDepositToken = await SeniorDepositToken.deploy();

    await seniorDepositToken.initialize(
      addressResolver.address,
      tus.address,
      tus.decimals(),
      tus.name(),
      tus.symbol(),
      ethers.utils.formatBytes32String('')
    );

    // deploy debt token
    const StableDebtToken = await ethers.getContractFactory('StableDebtToken');
    const stableDebtToken = await StableDebtToken.deploy();
    await stableDebtToken.initialize(
      tus.address,
      tus.decimals(),
      tus.name(),
      tus.symbol(),
      ethers.utils.formatBytes32String('')
    );

    const WadRayMath = await ethers.getContractFactory('WadRayMath');
    const wadRayMath = await WadRayMath.deploy();

    const DefaultReserveInterestRateStrategy = await ethers.getContractFactory(
      'DefaultReserveInterestRateStrategy',
      {
        libraries: {
          WadRayMath: wadRayMath.address,
        },
      }
    );
    // 50% 10% 20% 8%
    const defaultReserveInterestRateStrategy =
      await DefaultReserveInterestRateStrategy.deploy(
        '500000000000000000000000000',
        '100000000000000000000000000',
        '200000000000000000000000000',
        '80000000000000000000000000'
      );
    await voyager.initReserve(
      tus.address,
      juniorDepositToken.address,
      seniorDepositToken.address,
      '100000000000000000000000000',
      '900000000000000000000000000',
      stableDebtToken.address,
      defaultReserveInterestRateStrategy.address
    );

    const reserveData = await voyager.getReserveData(tus.address);
    //console.log(reserveData);
    await voyager.activeReserve(tus.address);
    const reserveFlags = await voyager.getReserveFlags(tus.address);
    expect(reserveFlags[0]).to.equal(true);
    expect(reserveFlags[1]).to.equal(false);
    expect(reserveFlags[2]).to.equal(false);

    escrowContract = await voyager.getLiquidityManagerEscrowContractAddress();
    await tus.increaseAllowance(escrowContract, '100000000000000000000');
  });

  it('Deposit junior liquidity should return correct value', async function () {
    const depositAmount = '1000000000000000000';
    await voyager.deposit(tus.address, 0, depositAmount, owner.address);
    const juniorTokenAmount = await juniorDepositToken.balanceOf(owner.address);
    expect(juniorTokenAmount).to.equal(BigNumber.from(depositAmount));
    expect(await tus.balanceOf(escrowContract)).to.equal(
      BigNumber.from(depositAmount)
    );

    expect(await voyager.liquidityRate(tus.address, '0')).to.equal('0');
    // deposit again
    await voyager.deposit(tus.address, 0, depositAmount, owner.address);
    expect(await voyager.liquidityRate(tus.address, '0')).to.equal('0');
  });

  it('Deposit senior liquidity should return correct value', async function () {
    const depositAmount = '1000000000000000000';
    await voyager.deposit(tus.address, 1, depositAmount, owner.address);
    const seniorTokenAmount = await seniorDepositToken.balanceOf(owner.address);
    expect(seniorTokenAmount).to.equal(BigNumber.from(depositAmount));

    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
    // deposit again
    await voyager.deposit(tus.address, 1, depositAmount, owner.address);
    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
  });
});

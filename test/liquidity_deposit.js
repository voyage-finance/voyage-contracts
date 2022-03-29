const { expect } = require('chai');

let owner;
let voyager;

describe('Reserve Init', function () {
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
      ethers.utils.formatBytes32String('liquidityManagerStorage'),
    ];
    const destinations = [
      liquidityManagerProxy.address,
      liquidityManagerStorage.address,
    ];

    await addressResolver.importAddresses(names, destinations);

    await liquidityManagerProxy.transferOwnership(voyager.address);
    await voyager.claimLiquidityManagerProxyOwnership();

    /******************************** init reserve ********************************/
    const wad = 1000000000000000000;

    // deploy Tus
    const Tus = await ethers.getContractFactory('Tus');
    const tus = await Tus.deploy(BigInt(1000) * BigInt(wad));

    // deploy junior deposit token
    const JuniorDepositToken = await ethers.getContractFactory(
      'JuniorDepositToken'
    );
    const juniorDepositToken = await JuniorDepositToken.deploy();

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
    const seniorDepositToken = SeniorDepositToken.deploy();

    await seniorDepositToken.initialize(
      addressResolver.address,
      tus.address,
      tus.decimals(),
      tus.name(),
      tus.symbol(),
      ethers.utils.formatBytes32String('')
    );
  });
});

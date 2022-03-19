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
    // deploy LiquidityManagerStorage contract
    const LiquidityManagerStorage = await ethers.getContractFactory(
      'LiquidityManagerStorage',
      {
        libraries: {
          ReserveLogic: reserveLogic.address,
        },
      }
    );
    const liquidityManagerStorage = await LiquidityManagerStorage.deploy(
      liquidityManager.address
    );

    // import vaultManager to AddressResolver
    const names = [
      ethers.utils.formatBytes32String('liquidityManagerProxyName'),
      ethers.utils.formatBytes32String('liquidityManagerStorage'),
    ];
    const destinations = [
      liquidityManagerProxy.address,
      liquidityManagerStorage.address,
    ];

    await addressResolver.importAddresses(names, destinations);

    await liquidityManagerProxy.transferOwnership(voyager.address);
    await voyager.claimLiquidityManagerProxyOwnership();
  });

  it('Init reserve should return correct value', async function () {
    const ray = '1000000000000000000000000000';
    const fakeAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
    // deploy mock tus contract as reserve
    const Tus = await ethers.getContractFactory('Tus');
    const tus = await Tus.deploy('1000000000000000000000');
    await voyager.initReserve(
      tus.address,
      fakeAddress,
      fakeAddress,
      '400000000000000000000000000',
      '600000000000000000000000000',
      fakeAddress,
      fakeAddress
    );
    const reserveState = await voyager.getReserveData(tus.address);
    expect(reserveState.currentJuniorLiquidityIndex).to.equal(ray);
    expect(reserveState.currentSeniorLiquidityIndex).to.equal(ray);

    // 0 represents junior
    const juniorLiquidityRate = await voyager.liquidityRate(tus.address, "0");
    expect(juniorLiquidityRate).to.equal('0');
  });
});

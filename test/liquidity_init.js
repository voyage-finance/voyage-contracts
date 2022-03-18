const { expect } = require('chai');

describe('Reserve Init', function () {
  it('Init reserve should return correct value', async function () {
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
});

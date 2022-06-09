const { expect } = require('chai');

let owner;
let voyager;
let liquidityManagerProxy;
let lm;
let voyageProtocolDataProvider;

describe('Reserve Init', function () {
  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    // deploy Voyager contract
    const Voyager = await ethers.getContractFactory('Voyager');
    voyager = await Voyager.deploy();

    // deploy AddressResolver contract
    const AddressResolver = await ethers.getContractFactory('AddressResolver');
    const addressResolver = await AddressResolver.deploy();

    // set AddressResolver address to Voyager
    await voyager.setAddressResolverAddress(addressResolver.address);

    // deploy LiquidityManagerProxy contract
    const LiquidityManagerProxy = await ethers.getContractFactory(
      'LiquidityManagerProxy'
    );
    liquidityManagerProxy = await LiquidityManagerProxy.deploy();

    // deploy ReserveLogic library
    const ReserveLogic = await ethers.getContractFactory('ReserveLogic');
    const reserveLogic = await ReserveLogic.deploy();

    // deploy LiquidityManager contract
    const LiquidityManager = await ethers.getContractFactory(
      'LiquidityManager',
      {
        libraries: {
          ReserveLogic: reserveLogic.address,
        },
      }
    );
    const liquidityManager = await LiquidityManager.deploy(
      liquidityManagerProxy.address,
      voyager.address
    );
    liquidityManagerProxy.setTarget(liquidityManager.address);
    lm = LiquidityManager.attach(liquidityManagerProxy.address);

    // deploy ValidationLogic library
    const ValidationLogic = await ethers.getContractFactory('ValidationLogic');
    const validationLogic = await ValidationLogic.deploy();

    // deploy DebtLogic library
    const DebtLogic = await ethers.getContractFactory('DebtLogic');
    const debtLogic = await DebtLogic.deploy();

    // deploy LiquidityManagerStorage contract
    const LiquidityManagerStorage = await ethers.getContractFactory(
      'LiquidityManagerStorage',
      {
        libraries: {
          ReserveLogic: reserveLogic.address,
          ValidationLogic: validationLogic.address,
          DebtLogic: debtLogic.address,
        },
      }
    );
    const liquidityManagerStorage = await LiquidityManagerStorage.deploy(
      liquidityManager.address
    );

    //deploy ACLManager
    const ACLManager = await ethers.getContractFactory('ACLManager');
    const aclManager = await ACLManager.deploy(owner.address);
    await aclManager.grantLiquidityManager(owner.address);
    await aclManager.grantVaultManager(owner.address);
    await aclManager.grantPoolManager(owner.address);

    // import vaultManager to AddressResolver
    const names = [
      ethers.utils.formatBytes32String('liquidityManagerProxy'),
      ethers.utils.formatBytes32String('liquidityManagerStorage'),
      ethers.utils.formatBytes32String('aclManager'),
    ];
    const destinations = [
      liquidityManagerProxy.address,
      liquidityManagerStorage.address,
      aclManager.address,
    ];

    await addressResolver.importAddresses(names, destinations);

    const VoyageProtocolDataProvider = await ethers.getContractFactory(
      'VoyageProtocolDataProvider'
    );
    voyageProtocolDataProvider = await VoyageProtocolDataProvider.deploy(
      addressResolver.address
    );
  });

  it('Init reserve should return correct value', async function () {
    const fakeAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
    // deploy mock tus contract as reserve
    const Tus = await ethers.getContractFactory('Tus');
    const tus = await Tus.deploy('1000000000000000000000');
    lm.initReserve(
      tus.address,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      '500000000000000000000000000'
    );

    // 0 represents junior
    const juniorLiquidityRate = await voyager.liquidityRate(tus.address, '0');
    expect(juniorLiquidityRate).to.equal('0');

    const poolTokens = await voyageProtocolDataProvider.getPoolTokens();
    expect(poolTokens.length).to.equal(1);
    expect(poolTokens[0].symbol).to.equal('TUS');
    expect(poolTokens[0].tokenAddress).to.equal(tus.address);
  });

  it('Active reserve should return correct value', async function () {
    const fakeAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
    // deploy mock tus contract as reserve
    const Tus = await ethers.getContractFactory('Tus');
    const tus = await Tus.deploy('1000000000000000000000');
    lm.initReserve(
      tus.address,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      '500000000000000000000000000'
    );
    const flags = await voyager.getReserveFlags(tus.address);
    expect(flags[0]).to.equal(false);

    await expect(lm.activeReserve(tus.address))
      .to.emit(lm, 'ReserveActivated')
      .withArgs(tus.address);
    const newFlags = await voyager.getReserveFlags(tus.address);
    expect(newFlags[0]).to.equal(true);
  });
});

const { expect } = require('chai');
const {deployments, ethers} = require("hardhat");

let addressResolver;
let tus;

describe('Initialize Deposit Token', function () {
  beforeEach(async function () {
    await deployments.fixture([
      'AddressResolver',
      'Voyager',
      'ACLManager',
      'LiquidityManagerProxy',
      'LiquidityManager',
      'LiquidityManagerStorage',
      'Tokenization',
      'SetAddressResolver'
    ]);
    addressResolver = await ethers.getContract('AddressResolver');
    tus = await ethers.getContract('Tus');
  });

  it('Initialize junior token should return correct value', async function () {
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

    const name = await juniorDepositToken.name();
    expect(name).to.equal('Treasure Under Sea');
  });

  it('Initialize Senior token should return correct value', async function () {
    const SeniorDepositToken = await ethers.getContractFactory(
      'SeniorDepositToken'
    );
    const seniorDepositToken = await SeniorDepositToken.deploy();

    await seniorDepositToken.initialize(
      addressResolver.address,
      tus.address,
      tus.decimals(),
      tus.name(),
      tus.symbol(),
      ethers.utils.formatBytes32String('')
    );

    const name = await seniorDepositToken.name();
    expect(name).to.equal('Treasure Under Sea');
  });

  it('Initialize junior token twice should report error', async function () {
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
    await expect(
      juniorDepositToken.initialize(
        addressResolver.address,
        tus.address,
        tus.decimals(),
        tus.name(),
        tus.symbol(),
        ethers.utils.formatBytes32String('')
      )
    ).to.be.revertedWith('Contract instance has already been initialized');
  });

  it('Initialize senior token twice should report error', async function () {
    const SeniorDepositToken = await ethers.getContractFactory(
      'SeniorDepositToken'
    );
    const seniorDepositToken = await SeniorDepositToken.deploy();

    await seniorDepositToken.initialize(
      addressResolver.address,
      tus.address,
      tus.decimals(),
      tus.name(),
      tus.symbol(),
      ethers.utils.formatBytes32String('')
    );
    await expect(
      seniorDepositToken.initialize(
        addressResolver.address,
        tus.address,
        tus.decimals(),
        tus.name(),
        tus.symbol(),
        ethers.utils.formatBytes32String('')
      )
    ).to.be.revertedWith('Contract instance has already been initialized');
  });
});

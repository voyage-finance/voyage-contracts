const { expect } = require('chai');

let addressResolver;
let tus;

describe('Initialize Deposit Token', function () {
  beforeEach(async function () {
    const AddressResolver = await ethers.getContractFactory('AddressResolver');
    addressResolver = await AddressResolver.deploy();

    const Tus = await ethers.getContractFactory('Tus');
    tus = await Tus.deploy('1000000000000000000000');
  });

  it('Initialize junior token should return correct value', async function () {
    const JuniorDepositToken = await ethers.getContractFactory(
      'JuniorDepositToken'
    );
    const juniorDepositToken = await JuniorDepositToken.deploy();

    await juniorDepositToken.initialize(
      addressResolver.address,
      tus.address,
      18,
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
      18,
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
      18,
      tus.name(),
      tus.symbol(),
      ethers.utils.formatBytes32String('')
    );
    await expect(
      juniorDepositToken.initialize(
        addressResolver.address,
        tus.address,
        18,
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
      18,
      tus.name(),
      tus.symbol(),
      ethers.utils.formatBytes32String('')
    );
    await expect(
      seniorDepositToken.initialize(
        addressResolver.address,
        tus.address,
        18,
        tus.name(),
        tus.symbol(),
        ethers.utils.formatBytes32String('')
      )
    ).to.be.revertedWith('Contract instance has already been initialized');
  });
});

const { expect } = require('chai');

describe('Initialize Deposit Token', function () {
  it('Initialize junior token should return correct value', async function () {
    // deploy AddressResolver contract
    const AddressResolver = await ethers.getContractFactory('AddressResolver');
    const addressResolver = await AddressResolver.deploy();

    const Tus = await ethers.getContractFactory('Tus');
    const tus = await Tus.deploy('1000000000000000000000');

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

  it('Initialize junior token twice should report error', async function () {
    // deploy AddressResolver contract
    const AddressResolver = await ethers.getContractFactory('AddressResolver');
    const addressResolver = await AddressResolver.deploy();

    const Tus = await ethers.getContractFactory('Tus');
    const tus = await Tus.deploy('1000000000000000000000');

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
});

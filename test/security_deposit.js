const { expect } = require('chai');

let voyager;
let vaultManagerProxy;
let vaultManager;
let vaultStorage;
let owner;

describe('Security Deposit', function () {
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

    // deploy VaultManagerProxy contract
    const VaultManagerProxy = await ethers.getContractFactory(
      'VaultManagerProxy'
    );
    vaultManagerProxy = await VaultManagerProxy.deploy();

    // deploy VaultManager contract
    const VaultManager = await ethers.getContractFactory('VaultManager');
    vaultManager = await VaultManager.deploy(
      vaultManagerProxy.address,
      voyager.address
    );

    // update VaultManagerProxy, set target contract
    vaultManagerProxy.setTarget(vaultManager.address);

    // deploy VaultStorage contract
    const VaultStorage = await ethers.getContractFactory('VaultStorage');
    vaultStorage = await VaultStorage.deploy(vaultManager.address);

    // import vaultManager to AddressResolver
    const names = [
      ethers.utils.formatBytes32String('vaultManagerProxy'),
      ethers.utils.formatBytes32String('vaultStorage'),
    ];
    const destinations = [vaultManagerProxy.address, vaultStorage.address];
    await addressResolver.importAddresses(names, destinations);

    await vaultManagerProxy.transferOwnership(voyager.address);
    await voyager.claimVaultManagerProxyOwnership();
  });

  it('Non Voyager call VaultManager should throw error', async function () {
    const [owner] = await ethers.getSigners();
    // deploy mock tus contract
    const Tus = await ethers.getContractFactory('Tus');
    const tus = await Tus.deploy('1000000000000000000000');
    await expect(
      vaultManager.setMaxSecurityDeposit(tus.address, '100000000000000000000')
    ).to.be.revertedWith('Only the proxy can call');
  });

  it('Security deposit setup should return correct value', async function () {
    const [owner] = await ethers.getSigners();
    // deploy mock tus contract
    const Tus = await ethers.getContractFactory('Tus');
    const tus = await Tus.deploy('1000000000000000000000');

    const amountBeforeSetting = await voyager.getMaxSecurityDeposit(
      tus.address
    );
    expect(amountBeforeSetting).to.equal('0');
    await voyager.setMaxSecurityDeposit(tus.address, '100000000000000000000');
    const amountAfterSetting = await voyager.getMaxSecurityDeposit(tus.address);
    expect(amountAfterSetting).to.equal('100000000000000000000');

    await voyager.removeMaxSecurityDeposit(tus.address);
    expect(amountBeforeSetting).to.equal('0');
  });

  it('Security deposit should return correct value', async function () {
    const [owner] = await ethers.getSigners();
    // create vault
    await voyager.createVault();

    const vaultAddress = await vaultStorage.getVaultAddress(owner.address);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddress);
    const securityDepositEscrowAddress =
      await vault.getSecurityDepositEscrowAddress();

    // deploy mock tus contract
    const Tus = await ethers.getContractFactory('Tus');
    const tus = await Tus.deploy('1000000000000000000000');
    await tus.increaseAllowance(
      securityDepositEscrowAddress,
      '10000000000000000000000'
    );

    await voyager.setMaxSecurityDeposit(tus.address, '100000000000000000000');

    //  init vault
    await voyager.initVault(owner.address, tus.address);
    const stakingContract = await vault.getStakingContractAddress();

    const SecurityDepositEscrow = await ethers.getContractFactory(
      'SecurityDepositEscrow'
    );
    const securityDepositEscrow = SecurityDepositEscrow.attach(
      securityDepositEscrowAddress
    );
    const depositAmount = await securityDepositEscrow.getDepositAmount(
      tus.address
    );
    expect(depositAmount).to.equal('0');

    await voyager.depositSecurity(
      owner.address,
      tus.address,
      '10000000000000000000'
    );
    const depositAmountAfter = await securityDepositEscrow.getDepositAmount(
      tus.address
    );
    expect(depositAmountAfter).to.equal('10000000000000000000');

    const SecurityDepositToken = await ethers.getContractFactory(
      'SecurityDepositToken'
    );
    const securityDepositToken = SecurityDepositToken.attach(
      await vault.getSecurityDepositTokenAddress()
    );
    const balanceOfSponsor = await securityDepositToken.balanceOf(
      owner.address
    );
    expect(balanceOfSponsor).to.equal('10000000000000000000');
  });
});

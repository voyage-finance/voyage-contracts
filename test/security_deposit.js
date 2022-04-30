const { expect } = require('chai');
const { ethers } = require('hardhat');

let voyager;
let vaultManagerProxy;
let vm;
let vaultManager;
let vaultStorage;
let owner;
let extCallACLProxy;
let extCallACL;
let tus;

describe('Security Deposit', function () {
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

    // deploy VaultManagerProxy contract
    const VaultManagerProxy = await ethers.getContractFactory(
      'VaultManagerProxy'
    );
    vaultManagerProxy = await VaultManagerProxy.deploy();

    // deploy VaultFactory contract
    const VaultFactory = await ethers.getContractFactory('VaultFactory');
    const vaultFactory = await VaultFactory.deploy();

    // deploy VaultManager contract
    const VaultManager = await ethers.getContractFactory('VaultManager');
    vaultManager = await VaultManager.deploy(
      vaultManagerProxy.address,
      addressResolver.address,
      voyager.address,
      vaultFactory.address
    );

    // update VaultManagerProxy, set target contract
    vaultManagerProxy.setTarget(vaultManager.address);
    vm = VaultManager.attach(vaultManagerProxy.address);

    // deploy VaultStorage contract
    const VaultStorage = await ethers.getContractFactory('VaultStorage');
    vaultStorage = await VaultStorage.deploy(vaultManager.address);

    // deploy ExtCallACL contract
    const ExtCallACLProxy = await ethers.getContractFactory('ExtCallACLProxy');
    extCallACLProxy = await ExtCallACLProxy.deploy();
    const ExtCallALC = await ethers.getContractFactory('ExtCallACL');
    extCallACL = await ExtCallALC.deploy(extCallACLProxy.address);
    await extCallACLProxy.setTarget(extCallACL.address);

    //deploy ACLManager
    const ACLManager = await ethers.getContractFactory('ACLManager');
    const aclManager = await ACLManager.deploy(owner.address);
    await aclManager.grantLiquidityManager(owner.address);
    await aclManager.grantVaultManager(owner.address);
    await aclManager.grantPoolManager(owner.address);
    await aclManager.grantVaultManagerContract(vaultManager.address);

    // import vaultManager to AddressResolver
    const names = [
      ethers.utils.formatBytes32String('voyager'),
      ethers.utils.formatBytes32String('vaultManagerProxy'),
      ethers.utils.formatBytes32String('vaultStorage'),
      ethers.utils.formatBytes32String('extCallACLProxy'),
      ethers.utils.formatBytes32String('aclManager'),
    ];

    const destinations = [
      voyager.address,
      vaultManagerProxy.address,
      vaultStorage.address,
      extCallACLProxy.address,
      aclManager.address,
    ];

    await addressResolver.importAddresses(names, destinations);

    await voyager.whitelistAddress([owner.address]);
    await voyager.whitelistFunction([
      ethers.utils.formatBytes32String('createVault'),
      ethers.utils.formatBytes32String('depositSecurity'),
      ethers.utils.formatBytes32String('redeemSecurity'),
    ]);
    // deploy mock tus contract
    const Tus = await ethers.getContractFactory('Tus');
    tus = await Tus.deploy('1000000000000000000000');
  });

  it('Non Voyager call VaultManager should throw error', async function () {
    const [owner] = await ethers.getSigners();

    await expect(
      vaultManager.setMaxSecurityDeposit(tus.address, '100000000000000000000')
    ).to.be.revertedWith('Only the proxy can call');
  });

  it('Security deposit setup should return correct value', async function () {
    await vm.setMaxSecurityDeposit(tus.address, '100000000000000000000');
    const amountAfterSetting = await voyager.getVaultConfig(tus.address);
    expect(amountAfterSetting.maxSecurityDeposit.toString()).to.equal(
      '100000000000000000000'
    );
  });

  it('Security deposit should return correct value', async function () {
    const [owner] = await ethers.getSigners();
    // create vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner.address, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner.address);
    await voyager.initVault(vaultAddr, tus.address);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = await Vault.attach(vaultAddr);
    const securityDepositEscrowAddress =
      await vault.getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(
      securityDepositEscrowAddress,
      '10000000000000000000000'
    );

    await vm.setMaxSecurityDeposit(tus.address, '100000000000000000000');
    const SecurityDepositEscrow = await ethers.getContractFactory(
      'SecurityDepositEscrow'
    );
    const securityDepositEscrow = await SecurityDepositEscrow.attach(
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

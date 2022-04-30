const { expect } = require('chai');
const { ethers } = require('hardhat');

let voyager;
let vaultManagerProxy;
let vaultManager;
let vaultStorage;
let owner;
let tus;

describe('Vault Creation', function () {
  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    // deploy Voyager contract
    const Voyager = await ethers.getContractFactory('Voyager');
    voyager = await Voyager.deploy();

    // deploy AddressResolver contract
    const AddressResolver = await ethers.getContractFactory('AddressResolver');
    const addressResolver = await AddressResolver.deploy();

    // deploy VaultFactory contract
    const VaultFactory = await ethers.getContractFactory('VaultFactory');
    const vaultFactory = await VaultFactory.deploy();

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
      addressResolver.address,
      voyager.address,
      vaultFactory.address
    );

    // update VaultManagerProxy, set target contract
    vaultManagerProxy.setTarget(vaultManager.address);

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
      ethers.utils.formatBytes32String('vaultManager'),
      ethers.utils.formatBytes32String('vaultStorage'),
      ethers.utils.formatBytes32String('extCallACLProxy'),
      ethers.utils.formatBytes32String('aclManager'),
    ];

    const destinations = [
      voyager.address,
      vaultManagerProxy.address,
      vaultManager.address,
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

  it('New user should have zero address vault', async function () {
    expect(await vaultManager.getVault(owner.address)).to.equal(
      '0x0000000000000000000000000000000000000000'
    );
  });

  it('Create Vault should return a valid vault contract', async function () {
    // create vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner.address, tus.address, salt);
    const vaultAddress = await voyager.getVault(owner.address);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddress);
  });

  it('Created Vault should have own a valid escrow contract', async function () {
    const [owner] = await ethers.getSigners();
    // create vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner.address, tus.address, salt);
    const vaultAddress = await vaultStorage.getVaultAddress(owner.address);
    await voyager.initVault(vaultAddress, tus.address);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddress);
    const SecurityDepositEscrow = await ethers.getContractFactory(
      'SecurityDepositEscrow'
    );
    const securityDepositEscrowAddress =
      await vault.getSecurityDepositEscrowAddress();
    const securityDepositEscrow = SecurityDepositEscrow.attach(
      securityDepositEscrowAddress
    );
    expect(await securityDepositEscrow.getVersion()).to.equal(
      'SecurityDepositEscrow 0.0.1'
    );
  });
});

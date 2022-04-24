const { expect } = require('chai');
const {ethers} = require("hardhat");

let voyager;
let vaultManagerProxy;
let vaultManager;
let vm;
let vaultStorage;
let owner;
let tus;
let securityDepositEscrow;

describe('Security Redeem', function () {
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
      ethers.utils.formatBytes32String('vaultManagerProxy'),
      ethers.utils.formatBytes32String('vaultManager'),
      ethers.utils.formatBytes32String('vaultStorage'),
      ethers.utils.formatBytes32String('extCallACLProxy'),
      ethers.utils.formatBytes32String('aclManager'),
    ];
    const destinations = [
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


    // create vault
    const salt = ethers.utils.formatBytes32String((Math.random() + 1).toString(36).substring(7))
    await voyager.createVault(tus.address, salt);

    const vaultAddress = await vaultStorage.getVaultAddress(owner.address);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddress);
    const vaultAddr = await voyager.getVault(owner.address);
    await voyager.initVault(vaultAddr, tus.address);
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
    securityDepositEscrow = SecurityDepositEscrow.attach(
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

  it('Security redeem within lockup time should throw error', async function () {
    const eligibleAmount = await voyager.eligibleAmount(
      owner.address,
      tus.address,
      owner.address
    );
    expect(eligibleAmount).to.equal('0');
    await expect(
      voyager.redeemSecurity(owner.address, tus.address, '1000000000000000000')
    ).to.be.revertedWith('Do not have enough amount to withdraw');
  });

  it('Security redeem with no slash should return correct value', async function () {
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    await ethers.provider.send('evm_mine');

    const eligibleAmount = await voyager.eligibleAmount(
      owner.address,
      tus.address,
      owner.address
    );
    expect(eligibleAmount).to.equal('10000000000000000000');
    await voyager.redeemSecurity(
      owner.address,
      tus.address,
      '1000000000000000000'
    );
  });

  it('Security redeem with slash should return correct value', async function () {
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    await ethers.provider.send('evm_mine');

    const beforeSlashing = await tus.balanceOf(securityDepositEscrow.address);
    expect(beforeSlashing).to.equal('10000000000000000000');

    await voyager.slash(
      owner.address,
      tus.address,
      owner.address,
      '1000000000000000000'
    );

    const afterSlashing = await tus.balanceOf(securityDepositEscrow.address);
    expect(afterSlashing).to.equal('9000000000000000000');

    const eligibleAmount = await voyager.eligibleAmount(
      owner.address,
      tus.address,
      owner.address
    );
    expect(eligibleAmount).to.equal('10000000000000000000');
  });
});

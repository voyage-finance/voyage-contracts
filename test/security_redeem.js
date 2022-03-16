const { expect } = require('chai');

let voyager;
let vaultManagerProxy;
let vaultManager;
let vaultStorage;
let owner;
let tus;
let securityDepositEscrow;

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

    // create vault
    await voyager.createVault();

    const vaultAddress = await vaultStorage.getVaultAddress(owner.address);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddress);
    const securityDepositEscrowAddress =
      await vault.getSecurityDepositEscrowAddress();

    // deploy mock tus contract
    const Tus = await ethers.getContractFactory('Tus');
    tus = await Tus.deploy('1000000000000000000000');
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
    const underlyingBalance = await voyager.underlyingBalance(
      owner.address,
      tus.address,
      owner.address
    );
    expect(underlyingBalance).to.equal('10000000000000000000');
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
    const underlyingBalance = await voyager.underlyingBalance(
      owner.address,
      tus.address,
      owner.address
    );
    expect(underlyingBalance).to.equal('10000000000000000000');
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

    await voyager.slash(owner.address, tus.address, owner.address, "1000000000000000000")

    const afterSlashing = await tus.balanceOf(securityDepositEscrow.address);
    expect(afterSlashing).to.equal('9000000000000000000');

    const eligibleAmount = await voyager.eligibleAmount(
        owner.address,
        tus.address,
        owner.address
    );
    expect(eligibleAmount).to.equal('10000000000000000000');

    const underlyingBalance = await voyager.underlyingBalance(
        owner.address,
        tus.address,
        owner.address
    );
    expect(underlyingBalance).to.equal('9000000000000000000');
  });

});

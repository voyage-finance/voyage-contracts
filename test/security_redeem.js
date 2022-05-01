const { expect } = require('chai');
const { ethers, getNamedAccounts, deployments } = require('hardhat');

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
    ({ owner } = await getNamedAccounts());
    await deployments.fixture([
      'AddressResolver',
      'Voyager',
      'ACLManager',
      'LiquidityManagerProxy',
      'LiquidityManager',
      'LiquidityManagerStorage',
      'Tokenization',
      'SetAddressResolver',
      'LoanManager',
      'VaultManager',
    ]);
    vaultManagerProxy = await ethers.getContract('VaultManagerProxy');
    tus = await ethers.getContract('Tus');
    voyager = await ethers.getContract('Voyager');
    vaultManager = await ethers.getContract('VaultManager');
    vaultStorage = await ethers.getContract('VaultStorage');

    await voyager.whitelistAddress([owner]);
    await voyager.whitelistFunction([
      ethers.utils.formatBytes32String('createVault'),
      ethers.utils.formatBytes32String('depositSecurity'),
      ethers.utils.formatBytes32String('redeemSecurity'),
    ]);

    // create vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);

    const vaultAddress = await vaultStorage.getVaultAddress(owner);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddress);
    const vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);
    const securityDepositEscrowAddress =
      await vault.getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(
      securityDepositEscrowAddress,
      '10000000000000000000000'
    );
    const VaultManager = await ethers.getContractFactory('VaultManager');
    vm = VaultManager.attach(vaultManagerProxy.address);

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

    await voyager.depositSecurity(owner, tus.address, '10000000000000000000');
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
    const balanceOfSponsor = await securityDepositToken.balanceOf(owner);
    expect(balanceOfSponsor).to.equal('10000000000000000000');
  });

  it('Security redeem within lockup time should throw error', async function () {
    const eligibleAmount = await voyager.eligibleAmount(
      owner,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal('0');
    await expect(
      voyager.redeemSecurity(owner, tus.address, '1000000000000000000')
    ).to.be.revertedWith(
      'Vault: cannot redeem more than withdrawable deposit amount'
    );
  });

  it('Security redeem with no slash should return correct value', async function () {
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    await ethers.provider.send('evm_mine');

    const eligibleAmount = await voyager.eligibleAmount(
      owner,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal('10000000000000000000');
    await voyager.redeemSecurity(owner, tus.address, '1000000000000000000');
  });

  it('Security redeem with slash should return correct value', async function () {
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    await ethers.provider.send('evm_mine');

    const beforeSlashing = await tus.balanceOf(securityDepositEscrow.address);
    expect(beforeSlashing).to.equal('10000000000000000000');

    await voyager.slash(owner, tus.address, owner, '1000000000000000000');

    const afterSlashing = await tus.balanceOf(securityDepositEscrow.address);
    expect(afterSlashing).to.equal('9000000000000000000');

    const eligibleAmount = await voyager.eligibleAmount(
      owner,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal('10000000000000000000');
  });
});

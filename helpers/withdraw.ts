import { deployments } from 'hardhat';
import { MAX_UINT_256 } from './math';

export const setupWithdrawalTestSuite = deployments.createFixture(
  async ({ getNamedAccounts, ethers }) => {
    const { owner } = await getNamedAccounts();
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
    const liquidityManagerProxy = await ethers.getContract(
      'LiquidityManagerProxy'
    );
    const liquidityManager = await ethers.getContract('LiquidityManager');
    const juniorDepositToken = await ethers.getContract('JuniorDepositToken');
    const seniorDepositToken = await ethers.getContract('SeniorDepositToken');
    const defaultReserveInterestRateStrategy = await ethers.getContract(
      'DefaultReserveInterestRateStrategy'
    );
    const healthStrategyAddress = await ethers.getContract(
      'DefaultHealthStrategy'
    );
    const addressResolver = await ethers.getContract('AddressResolver');
    const tus = await ethers.getContract('Tus');
    const voyager = await ethers.getContract('Voyager');
    const vaultManager = await ethers.getContract('VaultManager');
    await voyager.whitelistAddress([owner]);
    await voyager.whitelistFunction([
      ethers.utils.formatBytes32String('createVault'),
      ethers.utils.formatBytes32String('depositSecurity'),
      ethers.utils.formatBytes32String('redeemSecurity'),
      ethers.utils.formatBytes32String('borrow'),
    ]);
    await tus.increaseAllowance(
      liquidityManager.address,
      '1000000000000000000000'
    );

    const vaultManagerProxy = await ethers.getContract('VaultManagerProxy');
    const VaultManager = await ethers.getContractFactory('VaultManager');
    const vm = await VaultManager.attach(vaultManagerProxy.address);
    const loanStrategy = await ethers.getContract('DefaultLoanStrategy');

    // deposit sufficient reserve
    const reserveLogic = await ethers.getContract('ReserveLogic');
    const LM = await ethers.getContractFactory('LiquidityManager', {
      libraries: { ReserveLogic: reserveLogic.address },
    });
    const lm = await LM.attach(liquidityManagerProxy.address);
    await lm.initReserve(
      tus.address,
      juniorDepositToken.address,
      seniorDepositToken.address,
      defaultReserveInterestRateStrategy.address,
      healthStrategyAddress.address,
      loanStrategy.address,
      '500000000000000000000000000'
    );
    // 100
    const depositAmount = '100000000000000000000';
    await lm.activeReserve(tus.address);
    vm.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
    await vm.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);

    // get security deposit escrow address
    const Vault = await ethers.getContractFactory('Vault');
    const escrowAddress = await Vault.attach(
      vaultAddr
    ).getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(escrowAddress, '1000000000000000000000');

    await voyager.depositSecurity(owner, tus.address, '100000000000000000000');

    await seniorDepositToken.approve(liquidityManager.address, MAX_UINT_256);
    await juniorDepositToken.approve(liquidityManager.address, MAX_UINT_256);

    return {
      seniorDepositToken,
      juniorDepositToken,
      liquidityManager,
      tus,
      voyager,
      vaultAddr,
      owner,
    };
  }
);

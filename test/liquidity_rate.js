// const { expect } = require('chai');
// const { deployments, ethers, getNamedAccounts } = require('hardhat');
// const { BigNumber } = require('ethers');
//
// let owner;
// let voyager;
// let liquidityManagerProxy;
// let liquidityManager;
// let juniorDepositToken;
// let seniorDepositToken;
// let stableDebtToken;
// let defaultReserveInterestRateStrategy;
// let healthStrategyAddress;
// let addressResolver;
// let vaultManager;
// let tus;
// let vm;
// let dataProvider;
// const RAY = BigNumber.from('1000000000000000000000000000');
//
// describe('Liquidity Rate', function () {
//   beforeEach(async function () {
//     ({ owner } = await getNamedAccounts());
//     await deployments.fixture([
//       'AddressResolver',
//       'Voyager',
//       'ACLManager',
//       'LiquidityManagerProxy',
//       'LiquidityManager',
//       'LiquidityManagerStorage',
//       'Tokenization',
//       'SetAddressResolver',
//       'LoanManager',
//       'VaultManager',
//       'VoyageProtocolDataProvider',
//     ]);
//     liquidityManagerProxy = await ethers.getContract('LiquidityManagerProxy');
//     liquidityManager = await ethers.getContract('LiquidityManager');
//     juniorDepositToken = await ethers.getContract('JuniorDepositToken');
//     seniorDepositToken = await ethers.getContract('SeniorDepositToken');
//     stableDebtToken = await ethers.getContract('StableDebtToken');
//     defaultReserveInterestRateStrategy = await ethers.getContract(
//       'DefaultReserveInterestRateStrategy'
//     );
//     healthStrategyAddress = await ethers.getContract('DefaultHealthStrategy');
//     addressResolver = await ethers.getContract('AddressResolver');
//     tus = await ethers.getContract('Tus');
//     voyager = await ethers.getContract('Voyager');
//     vaultManager = await ethers.getContract('VaultManager');
//     dataProvider = await ethers.getContract('VoyageProtocolDataProvider');
//     await voyager.whitelistAddress([owner]);
//     await voyager.whitelistFunction([
//       ethers.utils.formatBytes32String('createVault'),
//       ethers.utils.formatBytes32String('depositSecurity'),
//       ethers.utils.formatBytes32String('redeemSecurity'),
//       ethers.utils.formatBytes32String('borrow'),
//     ]);
//     await tus.increaseAllowance(liquidityManager.address, '1000000000000000000000');
//
//     const vaultManagerProxy = await ethers.getContract('VaultManagerProxy');
//     const VaultManager = await ethers.getContractFactory('VaultManager');
//     vm = await VaultManager.attach(vaultManagerProxy.address);
//   });
//
//   it('Liquidity rate', async function () {
//     // deposit sufficient reserve
//     const reserveLogic = await ethers.getContract('ReserveLogic');
//     const LM = await ethers.getContractFactory('LiquidityManager', {
//       libraries: { ReserveLogic: reserveLogic.address },
//     });
//     const lm = await LM.attach(liquidityManagerProxy.address);
//     const vaultManagerProxy = await ethers.getContract('VaultManagerProxy');
//     const VaultManager = await ethers.getContract('VaultManager');
//     const vm = VaultManager.attach(vaultManagerProxy.address);
//     await lm.initReserve(
//       tus.address,
//       juniorDepositToken.address,
//       seniorDepositToken.address,
//       '500000000000000000000000000',
//       '500000000000000000000000000',
//       stableDebtToken.address,
//       defaultReserveInterestRateStrategy.address,
//       healthStrategyAddress.address
//     );
//     // 100
//     const seniorDeposit = '100000000000000000000';
//     const juniorDeposit = '20000000000000000000';
//     await lm.activeReserve(tus.address);
//     vm.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
//     await voyager.deposit(tus.address, 1, seniorDeposit, owner);
//     await voyager.deposit(tus.address, 0, juniorDeposit, owner);
//
//     await vm.setSecurityDepositRequirement(
//       tus.address,
//       '100000000000000000000000000'
//     ); // 0.1
//
//     // create an empty vault
//     const salt = ethers.utils.formatBytes32String(
//       (Math.random() + 1).toString(36).substring(7)
//     );
//     await voyager.createVault(owner, tus.address, salt);
//     const vaultAddr = await voyager.getVault(owner);
//     await voyager.initVault(vaultAddr, tus.address);
//
//     // get security deposit escrow address
//     const Vault = await ethers.getContractFactory('Vault');
//     const escrowAddress = await Vault.attach(
//       vaultAddr
//     ).getSecurityDepositEscrowAddress();
//     await tus.increaseAllowance(escrowAddress, '1000000000000000000000');
//
//     await voyager.depositSecurity(owner, tus.address, '100000000000000000000');
//     await voyager.borrow(tus.address, '100000000000000000000', vaultAddr, 0);
//     await voyager.deposit(tus.address, 0, juniorDeposit, owner);
//
//     const dataPool = await dataProvider.getPoolData(tus.address);
//     const juniorLiquidityRate = dataPool.juniorLiquidityRate / RAY;
//     const seniorLiquidityRate = dataPool.seniorLiquidityRate / RAY;
//     console.log(juniorLiquidityRate.toPrecision(4));
//     console.log(seniorLiquidityRate.toPrecision(4));
//   });
// });

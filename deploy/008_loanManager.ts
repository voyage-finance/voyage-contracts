import { DeployFunction } from 'hardhat-deploy/types';
import { DefaultHealthStrategy, Tus } from '@contracts';
import TusABI from '../artifacts/contracts/mock/Tus.sol/Tus.json';
import { ethers } from 'hardhat';

const LOAN_MANAGER_NAME = 'LoanManager';
const LOAN_MANAGER_PROXY_NAME = 'LoanManagerProxy';
const LM_STORAGE_NAME = 'LiquidityManagerStorage';
const LM_NAME = 'LiquidityManager';
const LM_ESCROW_NAME = 'liquidityDepositEscrow';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute, read } = deployments;
  const { owner } = await getNamedAccounts();

  const AddressResolver = await deployments.get('AddressResolver');
  const Voyager = await deployments.get('Voyager');

  const LoanManagerProxy = await deploy(LOAN_MANAGER_PROXY_NAME, {
    from: owner,
    args: [AddressResolver.address],
    log: true,
  });

  const LoanManager = await deploy(LOAN_MANAGER_NAME, {
    from: owner,
    args: [LoanManagerProxy.address, Voyager.address],
    log: true,
  });

  await execute(
    'LoanManagerProxy',
    { from: owner, log: true },
    'setTarget',
    LoanManager.address
  );

  const names = [
    ethers.utils.formatBytes32String('loanManager'),
    ethers.utils.formatBytes32String('loanManagerProxy'),
  ];
  const destinations = [LoanManager.address, LoanManagerProxy.address];
  await execute(
    'AddressResolver',
    { from: owner, log: true },
    'importAddresses',
    names,
    destinations
  );

  await execute(
    LM_STORAGE_NAME,
    { from: owner, log: true },
    'setAssociatedContract',
    LoanManager.address
  );

  await execute(
    'ACLManager',
    { from: owner, log: true },
    'grantLoanManagerContract',
    LoanManager.address
  );
};

deployFn.dependencies = [
  'AddressResolver',
  'Voyager',
  LM_NAME,
  LM_STORAGE_NAME,
];
deployFn.tags = ['LoanManager'];

export default deployFn;

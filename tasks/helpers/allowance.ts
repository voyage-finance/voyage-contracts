import {  Voyage } from '@contracts';
import { task } from 'hardhat/config';

task('dev:allowance', 'prints allowance in pool')
  .addOptionalParam('reserve', 'The reserve to check.')
  .addOptionalParam('account', 'The account to check.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers, getNamedAccounts } = hre;
    const { owner } = await getNamedAccounts();
    const { reserve, account = owner } = params
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const depositTokens = await voyage.getDepositTokens(reserve);
    console.log("junior deposit token address: ", depositTokens[1]);
    console.log("senior deposit token address: ", depositTokens[0]);
    const JuniorDepositToken = await ethers.getContractFactory('JuniorDepositToken');
    const juniorDepositToken = await JuniorDepositToken.attach(depositTokens[1]);
    const SeniorDepositToken = await ethers.getContractFactory('SeniorDepositToken');
    const seniorDepositToken = await SeniorDepositToken.attach(depositTokens[0]);
    
    const juniorAllowance = await juniorDepositToken.allowance(account, voyage.address);
    console.log("junior allowance: ", juniorAllowance.toString());

    const seniorAllowance = await seniorDepositToken.allowance(account, voyage.address);
    console.log("senior allowance: ", seniorAllowance.toString());
  });

import { BigNumber } from 'ethers';
import { deployments as d } from 'hardhat';
import { AddressResolver } from '../typechain/AddressResolver';
import { ERC20 } from '../typechain/ERC20';
import { SeniorDepositToken } from '../typechain/SeniorDepositToken';
import { decimals } from './math';

const dec = decimals(18);
interface Args {
  principalBalance?: number;
  interestBalance?: number;
}

export const setupDepositTestSuite = d.createFixture<any, Args>(
  async ({ getNamedAccounts, ethers }, options = {}) => {
    const { owner } = await getNamedAccounts();
    await d.fixture(['AddressResolver', 'LiquidityManager', 'ACLManager']);

    const { principalBalance = 0, interestBalance = 0 } = options;
    await d.deploy('LoanManagerProxy', {
      from: owner,
      log: true,
    });
    await d.deploy('MockLoanManager', {
      from: owner,
      args: [
        BigNumber.from(principalBalance).mul(dec),
        BigNumber.from(interestBalance).mul(dec),
      ],
      log: true,
    });
    const loanManager = await ethers.getContract('MockLoanManager');

    const addressResolver = await ethers.getContract<AddressResolver>(
      'AddressResolver'
    );
    await addressResolver.importAddresses(
      [
        ethers.utils.formatBytes32String('loanManager'),
        ethers.utils.formatBytes32String('loanManagerProxy'),
      ],
      [loanManager.address]
    );

    await d.deploy('Tus', {
      args: [ethers.BigNumber.from(1_000_000_000).mul(dec)],
      from: owner,
      log: true,
    });
    const underlying = await ethers.getContract<ERC20>('Tus');

    await d.deploy('SeniorDepositToken', {
      from: owner,
      log: true,
      args: [
        addressResolver.address,
        underlying.address,
        'TUS Senior Tranche',
        'vsTUS',
      ],
    });
    const seniorDepositToken = await ethers.getContract<SeniorDepositToken>(
      'SeniorDepositToken'
    );

    return {
      seniorDepositToken,
      underlying,
      loanManager,
      decimals: dec,
    };
  }
);

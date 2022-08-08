import { BigNumber } from 'ethers';

export interface UserReserveData {
  juniorTrancheBalance: BigNumber;
  seniorTrancheBalance: BigNumber;
  decimals: number;
  [key: string]: BigNumber | number | string | Boolean;
}

export interface BorrowData {
  paidLoanNumber: number;
  nextLoanNumber: number;
  totalPrincipal: BigNumber;
  totalInterest: BigNumber;
  loans: Loan[];
  totalPaid: BigNumber;
  totalRedeemed: BigNumber;
}

export interface Loan {
  principal: BigNumber;
  interest: BigNumber;
  term: number;
  epoch: number;
  nper: number;
  apr: BigNumber;
  borrowAt: BigNumber;
  nextPaymentDue: BigNumber;
  totalPrincipalPaid: BigNumber;
  totalInterestPaid: BigNumber;
  paidTimes: number;
}

export interface ReserveData {
  currency: string;
  totalLiquidity: BigNumber;
  juniorLiquidity: BigNumber;
  seniorLiquidity: BigNumber;
  totalDebt: BigNumber;
  trancheRatio: BigNumber;
  decimals: number;
  symbol: string;
  isActive: boolean;
  [key: string]: BigNumber | number | string | Boolean;
}

export interface CreditLineData {
  totalDebt: BigNumber;
  loanlist: LoanList;
  // totalMargin: BigNumber;
  // withdrawableSecurityDeposit: BigNumber;
  // creditLimit: BigNumber;
  // spendableBalance: BigNumber;
  // gav: BigNumber;
  // ltv: BigNumber;
  // healthFactor: BigNumber;
}

export interface LoanList {
  head: BigNumber;
  tail: BigNumber;
}

export interface LoanDetail {
  principal: BigNumber;
  interest: BigNumber;
  nper: BigNumber;
}

export interface PoolConfiguration {
  liquidationBonus: BigNumber;
  loanInterval: BigNumber;
  loanTenure: BigNumber;
  incomeRatio: BigNumber;
  isInitialized: boolean;
  isActive: boolean;
}

export enum Tranche {
  Junior,
  Senior,
}

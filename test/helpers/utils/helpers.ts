import { BigNumber } from 'ethers';
import { DataProviderFacet } from 'typechain/DataProviderFacet';
import {
  CreditLineData,
  LoanDetail,
  PoolConfiguration,
  ReserveData,
  UserReserveData,
} from './interfaces';

export const getReserveData = async (
  helper: DataProviderFacet,
  collection: string
): Promise<ReserveData> => {
  const poolData = await helper.getPoolData(collection);
  const currency = poolData.currency;
  const totalLiquidity = BigNumber.from(poolData.totalLiquidity);
  const juniorLiquidity = BigNumber.from(poolData.juniorLiquidity);
  const seniorLiquidity = BigNumber.from(poolData.seniorLiquidity);
  const totalDebt = BigNumber.from(poolData.totalDebt);
  const utilizationRate = BigNumber.from(poolData.utilizationRate);
  const trancheRatio = BigNumber.from(poolData.trancheRatio);
  const decimals = poolData.decimals.toNumber();
  const symbol = poolData.symbol;
  const isActive = poolData.isActive;
  return {
    currency,
    totalLiquidity,
    juniorLiquidity,
    seniorLiquidity,
    totalDebt,
    utilizationRate,
    trancheRatio,
    decimals,
    symbol,
    isActive,
  };
};

export const getUserPoolData = async (
  helper: DataProviderFacet,
  collection: string,
  user: string
): Promise<UserReserveData> => {
  const userPoolData = await helper.getUserPoolData(collection, user);
  const juniorTrancheBalance = BigNumber.from(
    userPoolData.juniorTrancheBalance
  );
  const seniorTrancheBalance = BigNumber.from(
    userPoolData.seniorTrancheBalance
  );
  const decimals = userPoolData.decimals.toNumber();
  return { juniorTrancheBalance, seniorTrancheBalance, decimals };
};

export const getLoanDetail = async (
  helper: DataProviderFacet,
  collection: string,
  vault: string,
  loanId: string
): Promise<LoanDetail> => {
  const loanDetail = await helper.getLoanDetail(vault, collection, loanId);
  const principal = loanDetail.principal;
  const interest = loanDetail.interest;
  const nper = loanDetail.nper;
  return { principal, interest, nper };
};

export const getPoolConfiguration = async (
  helper: DataProviderFacet,
  collection: string
): Promise<PoolConfiguration> => {
  const poolConfig = await helper.getPoolConfiguration(collection);
  return poolConfig;
};

export const getCreditLine = async (
  helper: DataProviderFacet,
  collection: string,
  vault: string
): Promise<CreditLineData> => {
  const creditLineData = await helper.getCreditLineData(vault, collection);
  const head = creditLineData.loanList.head;
  const tail = creditLineData.loanList.tail;
  const totalDebt = BigNumber.from(creditLineData.totalDebt);
  const loanlist = { head, tail };
  const totalMargin = BigNumber.from(creditLineData.totalMargin);
  const withdrawableSecurityDeposit = BigNumber.from(
    creditLineData.withdrawableSecurityDeposit
  );
  const creditLimit = BigNumber.from(creditLineData.creditLimit);
  const spendableBalance = BigNumber.from(creditLineData.spendableBalance);
  const gav = BigNumber.from(creditLineData.gav);
  const ltv = BigNumber.from(creditLineData.ltv);
  const healthFactor = BigNumber.from(creditLineData.healthFactor);
  return {
    totalDebt,
    loanlist,
    // totalMargin,
    // withdrawableSecurityDeposit,
    creditLimit,
    // spendableBalance,
    // gav,
    // ltv,
    // healthFactor,
  };
};

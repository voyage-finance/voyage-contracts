import { ether } from '@opengsn/common';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { Crab } from 'typechain/Crab';
import { DataProviderFacet } from 'typechain/DataProviderFacet';
import {
  CreditLineData,
  LoanDetail,
  PMT,
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

export const getOwnerOf = async (
  collection: string,
  tokenId: string
): Promise<string> => {
  const Crab = await ethers.getContractFactory('Crab');
  const crab = Crab.attach(collection);
  const owner = await crab.ownerOf(tokenId);
  return owner;
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
  const term = loanDetail.term;
  const epoch = loanDetail.epoch;
  const nper = loanDetail.nper;
  const pmt = <PMT>{};
  pmt.principal = loanDetail.pmt.principal;
  pmt.interest = loanDetail.pmt.interest;
  pmt.pmt = loanDetail.pmt.pmt;
  const apr = loanDetail.apr;
  const totalPrincipalPaid = loanDetail.totalPrincipalPaid;
  const totalInterestPaid = loanDetail.totalInterestPaid;
  const paidTimes = loanDetail.paidTimes;
  return {
    principal,
    interest,
    term,
    epoch,
    nper,
    pmt,
    apr,
    totalPrincipalPaid,
    totalInterestPaid,
    paidTimes,
  };
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
  const head = BigNumber.from(creditLineData.loanList.head);
  const tail = BigNumber.from(creditLineData.loanList.tail);
  const totalDebt = BigNumber.from(creditLineData.totalDebt);
  const loanlist = { head, tail };
  return {
    totalDebt,
    loanlist,
  };
};

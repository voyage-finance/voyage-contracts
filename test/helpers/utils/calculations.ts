import {
  CreditLineData,
  ReserveData,
  Tranche,
  UserReserveData,
} from './interfaces';
import { ONE_YEAR, RAY, MAX_UINT_AMOUNT, PERCENTAGE_FACTOR } from './constants';
import './wadraymath';
import { BigNumber } from 'ethers';
import { expect } from 'chai';

export const calcExpectedUserDataAfterDeposit = (
  amountDeposit: string,
  tranche: string,
  reserveDataBeforeAction: ReserveData,
  reserveDataAfterAction: ReserveData,
  userDataBeforeAction: UserReserveData,
  txTimestamp: BigNumber,
  currentTimestamp: BigNumber,
  txCost: BigNumber
): UserReserveData => {
  const expectedUserData = <UserReserveData>{};
  if (tranche == Tranche.Junior.toString()) {
    expectedUserData.juniorTrancheBalance = BigNumber.from(amountDeposit);
    expectedUserData.seniorDepositToken =
      userDataBeforeAction.seniorTrancheBalance;
  } else {
    expectedUserData.juniorDepositToken =
      userDataBeforeAction.juniorTrancheBalance;
    expectedUserData.seniorTrancheBalance = BigNumber.from(amountDeposit);
  }
  expectedUserData.decimals = userDataBeforeAction.decimals;
  return expectedUserData;
};

export const calcExpectedReserveDataAfterDeposit = (
  amountDeposit: string,
  tranche: string,
  reserveDataBeforeAction: ReserveData
): ReserveData => {
  const expectedReserveData: ReserveData = <ReserveData>{};
  expectedReserveData.totalLiquidity = BigNumber.from(amountDeposit);
  if (tranche == Tranche.Junior.toString()) {
    expectedReserveData.juniorLiquidity = BigNumber.from(amountDeposit);
    expectedReserveData.seniorLiquidity = BigNumber.from(0);
  } else {
    expectedReserveData.juniorLiquidity = BigNumber.from(0);
    expectedReserveData.seniorLiquidity = BigNumber.from(amountDeposit);
  }
  expectedReserveData.totalDebt = reserveDataBeforeAction.totalDebt;
  expectedReserveData.trancheRatio = reserveDataBeforeAction.trancheRatio;
  expectedReserveData.decimals = reserveDataBeforeAction.decimals;
  expectedReserveData.symbol = reserveDataBeforeAction.symbol;
  expectedReserveData.isActive = reserveDataBeforeAction.isActive;
  return expectedReserveData;
};

export const calcExpectedReserveDataAfterBorrow = (
  amountBorrow: string,
  reserveDataBeforeAction: ReserveData
): ReserveData => {
  const expectedReserveData: ReserveData = <ReserveData>{};
  expectedReserveData.juniorLiquidity = reserveDataBeforeAction.juniorLiquidity;
  expectedReserveData.seniorLiquidity = reserveDataBeforeAction.seniorLiquidity;
  expectedReserveData.totalLiquidity = reserveDataBeforeAction.totalLiquidity;
  expectedReserveData.totalDebt = BigNumber.from(amountBorrow);
  expectedReserveData.utilizationRate = BigNumber.from(amountBorrow)
    .wadToRay()
    .rayDiv(expectedReserveData.seniorLiquidity.wadToRay());
  expectedReserveData.trancheRatio = expectedReserveData.juniorLiquidity
    .wadToRay()
    .rayDiv(expectedReserveData.seniorLiquidity.wadToRay());
  expectedReserveData.decimals = reserveDataBeforeAction.decimals;
  expectedReserveData.symbol = reserveDataBeforeAction.symbol;
  expectedReserveData.isActive = reserveDataBeforeAction.isActive;
  return expectedReserveData;
};

export const calcExpectedCreditLineAfterBorrow = (
  amountBorrow: string,
  creditLineBeforeAction: CreditLineData
): CreditLineData => {
  const expectedCreditLineData: CreditLineData = <CreditLineData>{};
  expectedCreditLineData.totalDebt = creditLineBeforeAction.totalDebt.add(
    BigNumber.from(amountBorrow)
  );
  expectedCreditLineData.loanlist = {
    head: creditLineBeforeAction.loanlist.head,
    tail: creditLineBeforeAction.loanlist.tail.add(BigNumber.from(1)),
  };
  expectedCreditLineData.creditLimit = creditLineBeforeAction.creditLimit;
  return expectedCreditLineData;
};

export const caclExpectedReserveDataAfterWithdraw = (
  amountWithdraw: string,
  tranche: string,
  reserveDataBeforeAction: ReserveData
): ReserveData => {
  const expectedReserveData: ReserveData = <ReserveData>{};
  expectedReserveData.totalLiquidity =
    reserveDataBeforeAction.totalLiquidity.sub(BigNumber.from(amountWithdraw));
  if (tranche == Tranche.Junior.toString()) {
    expectedReserveData.juniorLiquidity =
      reserveDataBeforeAction.juniorLiquidity.sub(
        BigNumber.from(amountWithdraw)
      );
    expectedReserveData.seniorLiquidity =
      reserveDataBeforeAction.seniorLiquidity;
  } else {
    expectedReserveData.juniorLiquidity =
      reserveDataBeforeAction.juniorLiquidity;
    expectedReserveData.seniorLiquidity =
      reserveDataBeforeAction.seniorLiquidity.sub(
        BigNumber.from(amountWithdraw)
      );
  }
  expectedReserveData.totalDebt = reserveDataBeforeAction.totalDebt;
  expectedReserveData.trancheRatio = reserveDataBeforeAction.trancheRatio;
  expectedReserveData.decimals = reserveDataBeforeAction.decimals;
  expectedReserveData.symbol = reserveDataBeforeAction.symbol;
  expectedReserveData.isActive = reserveDataBeforeAction.isActive;
  return expectedReserveData;
};

import {
  CreditLineData,
  LoanDetail,
  PMT,
  ReserveData,
  Tranche,
  UserReserveData,
} from './interfaces';
import './wadraymath';
import { BigNumber } from 'ethers';

const RAY = BigNumber.from('1000000000000000000000000000');
const SECOND_PER_DAY = BigNumber.from('86400');
const SECOND_PER_YEAR = BigNumber.from('31556926');
const ZERO_VAULE = BigNumber.from(0);

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
  expectedReserveData.currency = reserveDataBeforeAction.currency;
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
  expectedReserveData.trancheRatio = expectedReserveData.juniorLiquidity
    .wadToRay()
    .rayDiv(expectedReserveData.seniorLiquidity.wadToRay());
  expectedReserveData.decimals = reserveDataBeforeAction.decimals;
  expectedReserveData.symbol = reserveDataBeforeAction.symbol;
  expectedReserveData.isActive = reserveDataBeforeAction.isActive;
  expectedReserveData.currency = reserveDataBeforeAction.currency;
  return expectedReserveData;
};

export const calcExpectedLoanDetailAfterBuyNow = (
  principal: BigNumber
): LoanDetail => {
  const loanDetail: LoanDetail = <LoanDetail>{};
  // hard code for now, should be reading from contract
  loanDetail.term = BigNumber.from(90);
  loanDetail.epoch = BigNumber.from(30);
  loanDetail.principal = principal;
  loanDetail.nper = calcNper(loanDetail);
  loanDetail.apr = BigNumber.from(18).mul(RAY).div(100);
  const effectiveInterestRate = calcEffectiveInterestRate(loanDetail);
  loanDetail.interest = loanDetail.principal.rayMul(effectiveInterestRate);
  loanDetail.pmt = calcPMT(loanDetail);
  loanDetail.totalPrincipalPaid = loanDetail.pmt.principal;
  loanDetail.totalPrincipalPaid = loanDetail.pmt.interest;
  loanDetail.paidTimes = BigNumber.from(1);
  return loanDetail;
};

export const calcExpectedLoanDetailAfterRepay = (
  loanDetailBefore: LoanDetail
): LoanDetail => {
  const loanDetail: LoanDetail = <LoanDetail>{};
  loanDetail.principal = loanDetailBefore.principal;
  loanDetail.interest = loanDetailBefore.interest;
  loanDetail.term = loanDetailBefore.term;
  loanDetail.epoch = loanDetailBefore.epoch;
  loanDetail.nper = loanDetailBefore.nper;
  loanDetail.pmt = loanDetailBefore.pmt;
  loanDetail.apr = loanDetailBefore.apr;
  loanDetail.totalPrincipalPaid = loanDetailBefore.totalPrincipalPaid.add(
    loanDetailBefore.pmt.principal
  );
  loanDetail.totalInterestPaid = loanDetailBefore.totalInterestPaid.add(
    loanDetail.pmt.interest
  );
  loanDetail.paidTimes = loanDetailBefore.paidTimes.add(1);
  return loanDetail;
};

export const calcEmptyLoanDetail = (): LoanDetail => {
  const loanDetailEmpty = <LoanDetail>{};
  loanDetailEmpty.principal = ZERO_VAULE;
  loanDetailEmpty.interest = ZERO_VAULE;
  loanDetailEmpty.term = ZERO_VAULE;
  loanDetailEmpty.epoch = ZERO_VAULE;
  loanDetailEmpty.nper = ZERO_VAULE;
  const pmt = <PMT>{};
  pmt.principal = ZERO_VAULE;
  pmt.interest = ZERO_VAULE;
  pmt.pmt = ZERO_VAULE;
  loanDetailEmpty.pmt = pmt;
  loanDetailEmpty.apr = ZERO_VAULE;
  loanDetailEmpty.totalPrincipalPaid = ZERO_VAULE;
  loanDetailEmpty.totalInterestPaid = ZERO_VAULE;
  loanDetailEmpty.paidTimes = ZERO_VAULE;
  return loanDetailEmpty;
};

export const calcNper = (loanDetail: LoanDetail): BigNumber => {
  const nper = loanDetail.term
    .mul(SECOND_PER_DAY)
    .div(loanDetail.epoch.mul(SECOND_PER_DAY));
  return nper;
};

export const calcEffectiveInterestRate = (
  loanDetail: LoanDetail
): BigNumber => {
  const periodPerYear = SECOND_PER_YEAR.div(
    loanDetail.epoch.mul(SECOND_PER_DAY)
  );
  const effectiveInterestRate = loanDetail.apr
    .mul(loanDetail.nper)
    .div(periodPerYear);
  return effectiveInterestRate;
};

export const calcPMT = (loanDetail: LoanDetail): PMT => {
  const pmt: PMT = <PMT>{};
  pmt.principal = loanDetail.principal.div(loanDetail.nper);
  pmt.interest = loanDetail.interest.div(loanDetail.nper);
  pmt.pmt = pmt.principal.add(pmt.interest);
  return pmt;
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
  expectedReserveData.currency = reserveDataBeforeAction.currency;
  return expectedReserveData;
};

export const caclExpectedReserveDataAfterRepay = (
  principal: BigNumber,
  interest: BigNumber,
  incomeRatio: BigNumber,
  reserveDataBeforeAction: ReserveData
): ReserveData => {
  const expectedReserveData: ReserveData = <ReserveData>{};
  const interestSenior = interest.percentMul(incomeRatio);
  const interestJunior = interest.sub(interestSenior);
  expectedReserveData.totalLiquidity =
    reserveDataBeforeAction.totalLiquidity.add(interest);
  expectedReserveData.juniorLiquidity =
    reserveDataBeforeAction.juniorLiquidity.add(interestJunior);
  expectedReserveData.seniorLiquidity =
    reserveDataBeforeAction.seniorLiquidity.add(interestSenior);
  expectedReserveData.totalDebt =
    reserveDataBeforeAction.totalDebt.sub(principal);
  expectedReserveData.trancheRatio = expectedReserveData.juniorLiquidity
    .wadToRay()
    .rayDiv(expectedReserveData.seniorLiquidity.wadToRay());
  expectedReserveData.decimals = reserveDataBeforeAction.decimals;
  expectedReserveData.symbol = reserveDataBeforeAction.symbol;
  expectedReserveData.isActive = reserveDataBeforeAction.isActive;
  expectedReserveData.currency = reserveDataBeforeAction.currency;
  return expectedReserveData;
};

export const caclExpectedCreditLineDataAfterRepay = (
  principal: BigNumber,
  creditLineBefore: CreditLineData
): CreditLineData => {
  const expectedCreditLineData: CreditLineData = <CreditLineData>{};
  expectedCreditLineData.loanlist = {
    head: creditLineBefore.loanlist.head,
    tail: creditLineBefore.loanlist.tail.add(BigNumber.from(1)),
  };
  expectedCreditLineData.totalDebt = creditLineBefore.totalDebt.sub(principal);
  return expectedCreditLineData;
};

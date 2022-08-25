import { BigNumber, ContractReceipt } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TestEnv } from './make-suite';
import {
  caclExpectedCreditLineDataAfterRepay,
  caclExpectedReserveDataAfterRepay,
  caclExpectedReserveDataAfterWithdraw,
  calcEmptyLoanDetail,
  calcExpectedCreditLineAfterBorrow,
  calcExpectedLoanDetailAfterBuyNow,
  calcExpectedLoanDetailAfterRepay,
  calcExpectedReserveDataAfterBorrow,
  calcExpectedReserveDataAfterDeposit,
  calcExpectedUserDataAfterDeposit,
} from './utils/calculations';
import {
  getCreditLine,
  getLoanDetail,
  getOwnerOf,
  getPoolConfiguration,
  getReserveData,
  getUserPoolData,
} from './utils/helpers';
import {
  CreditLineData,
  LoanDetail,
  ReserveData,
  Tranche,
  UserReserveData,
} from './utils/interfaces';
import chai from 'chai';
import { ethers } from 'hardhat';

declare var hre: HardhatRuntimeEnvironment;

const { expect } = chai;

interface ActionsConfig {
  skipIntegrityCheck: boolean;
}

export const configuration: ActionsConfig = <ActionsConfig>{};

const almostEqualOrEqual = function (
  this: any,
  expected: ReserveData | UserReserveData,
  actual: ReserveData | UserReserveData
) {
  const keys = Object.keys(actual);

  keys.forEach((key) => {
    if (
      key === 'lastUpdateTimestamp' ||
      key === 'symbol' ||
      key === 'decimals'
    ) {
      // skipping consistency check on accessory data
      return;
    }

    this.assert(
      actual[key] != undefined,
      `Property ${key} is undefined in the actual data`
    );
    expect(
      expected[key] != undefined,
      `Property ${key} is undefined in the expected data`
    );

    if (actual[key] instanceof BigNumber) {
      const actualValue = <BigNumber>actual[key];
      const expectedValue = <BigNumber>expected[key];
    } else {
      this.assert(
        actual[key] !== null &&
          expected[key] !== null &&
          actual[key].toString() === expected[key].toString(),
        `expected #{act} to be equal #{exp} for property ${key}`,
        `expected #{act} to be equal #{exp} for property ${key}`,
        expected[key],
        actual[key]
      );
    }
  });
};

chai.use(function (chai: any, utils: any) {
  chai.Assertion.overwriteMethod(
    'almostEqualOrEqual',
    function (original: any) {
      return function (this: any, expected: ReserveData | UserReserveData) {
        const actual = (expected as ReserveData)
          ? <ReserveData>this._obj
          : <UserReserveData>this._obj;

        almostEqualOrEqual.apply(this, [expected, actual]);
      };
    }
  );
});

const expectEqual = (
  actual: UserReserveData | ReserveData | CreditLineData | LoanDetail | string,
  expected: UserReserveData | ReserveData | CreditLineData | LoanDetail | string
) => {
  if (!configuration.skipIntegrityCheck) {
    // @ts-ignore
    expect(actual).to.be.almostEqualOrEqual(expected);
  }
};

export const deposit = async (
  cname: string,
  tranche: string,
  amount: string,
  testEnv: TestEnv
) => {
  const collection = testEnv.collections.get(cname);
  const user = testEnv.users[0];
  const { reserveData: reserveDataBefore, userData: userDataBefore } =
    await getContractsData(collection!, user.address, testEnv);

  const txResult = await (
    await testEnv.voyage.deposit(collection!, tranche, amount)
  ).wait();

  const { txCost, txTimestamp } = await getTxCostAndTimestamp(txResult);

  const {
    reserveData: reserveDataAfter,
    userData: userDataAfter,
    timestamp,
  } = await getContractsData(collection!, user.address, testEnv);

  const expectedUserData = calcExpectedUserDataAfterDeposit(
    amount,
    tranche,
    reserveDataBefore,
    reserveDataAfter,
    userDataBefore,
    txTimestamp,
    timestamp,
    txCost
  );

  const expectedReserveData = calcExpectedReserveDataAfterDeposit(
    amount,
    tranche,
    reserveDataBefore
  );

  expectEqual(userDataAfter, expectedUserData);
  expectEqual(reserveDataAfter, expectedReserveData);
};

export const withdraw = async (
  cname: string,
  tranche: string,
  amount: string,
  testEnv: TestEnv
) => {
  const collection = testEnv.collections.get(cname);
  const user = testEnv.users[0];
  const { reserveData: reserveDataBefore, userData: userDataBefore } =
    await getContractsData(collection!, user.address, testEnv);

  const txResult = await (
    await testEnv.voyage.withdraw(collection!, tranche, amount)
  ).wait();

  const {
    reserveData: reserveDataAfter,
    userData: userDataAfter,
    timestamp,
  } = await getContractsData(collection!, user.address, testEnv);

  const expectedReserveData = caclExpectedReserveDataAfterWithdraw(
    amount,
    tranche,
    reserveDataBefore
  );
  expectEqual(reserveDataAfter, expectedReserveData);
};

export const buyNow = async (
  cname: string,
  tokenId: string,
  nftprice: string,
  purchasingData: string,
  expected: string,
  userIndex: number,
  vault: string,
  testEnv: TestEnv
) => {
  const collection = testEnv.collections.get(cname);
  const user = testEnv.users[userIndex];

  const {
    reserveData: reserveDataBefore,
    userData: userDataBefore,
    creditLine: creditLineBefore,
  } = await getContractsData(collection!, user.address, testEnv);

  await testEnv.priceOracle.updateTwap(collection!, nftprice);
  if (expected != 'success') {
    await expect(
      testEnv.voyage
        .connect(user.signer)
        .buyNow(
          collection!,
          tokenId,
          vault!,
          testEnv.marketplace.address,
          purchasingData
        )
    ).to.be.revertedWithCustomError(testEnv.voyage, expected);
    return;
  }

  const txResult = await (
    await testEnv.voyage
      .connect(user.signer)
      .buyNow(
        collection!,
        tokenId,
        vault!,
        testEnv.marketplace.address,
        purchasingData
      )
  ).wait();

  const { txCost, txTimestamp } = await getTxCostAndTimestamp(txResult);

  const {
    reserveData: reserveDataAfter,
    userData: userDataAfter,
    creditLine: creditLineAfter,
    timestamp,
  } = await getContractsData(collection!, user.address, testEnv);

  console.log('credit line: ', creditLineAfter.loanlist.tail.toString());

  const loanDetail = await getLoanDetail(
    testEnv.voyage,
    collection!,
    vault!,
    '0'
  );

  const expectedReserveData = calcExpectedReserveDataAfterBorrow(
    nftprice.toString(),
    reserveDataBefore
  );

  const expectedCreditLineData = calcExpectedCreditLineAfterBorrow(
    nftprice.toString(),
    creditLineBefore
  );

  const principal = BigNumber.from('10000000000000000000');
  const expectedLoanDetail = calcExpectedLoanDetailAfterBuyNow(principal);

  expectEqual(reserveDataAfter, expectedReserveData);
  expectEqual(creditLineAfter, expectedCreditLineData);
  expectEqual(loanDetail, expectedLoanDetail);
};

export const repay = async (
  cname: string,
  loan: string,
  expected: string,
  testEnv: TestEnv
) => {
  const collection = testEnv.collections.get(cname);
  const user = testEnv.users[0];
  const vault = testEnv.vaults.get(user.address);

  const {
    reserveData: reserveDataBefore,
    userData: userDataBefore,
    creditLine: creditLineBefore,
  } = await getContractsData(collection!, user.address, testEnv);

  const loanDetailBefore = await getLoanDetail(
    testEnv.voyage,
    collection!,
    vault!,
    loan
  );

  const poolConfg = await getPoolConfiguration(testEnv.voyage, collection!);
  const incomeRatio = poolConfg.incomeRatio;

  if (expected != 'success') {
    await expect(
      testEnv.voyage.repay(collection!, '0', vault!)
    ).to.be.revertedWithCustomError(testEnv.voyage, expected);
    return;
  }

  const txResult = await (
    await testEnv.voyage.repay(collection!, '0', vault!)
  ).wait();

  const loanDetailAfter = await getLoanDetail(
    testEnv.voyage,
    collection!,
    vault!,
    loan
  );
  const {
    reserveData: reserveDataAfter,
    userData: userDataAfter,
    creditLine: creditLineAfter,
  } = await getContractsData(collection!, user.address, testEnv);

  const expectedReserveData = await caclExpectedReserveDataAfterRepay(
    loanDetailBefore.principal.div(loanDetailBefore.nper),
    loanDetailBefore.interest.div(loanDetailBefore.nper),
    incomeRatio,
    reserveDataBefore
  );

  const expectedCreditLineData = await caclExpectedCreditLineDataAfterRepay(
    loanDetailBefore.principal.div(loanDetailBefore.nper),
    creditLineBefore
  );

  const expectedLoanDetailData = await calcExpectedLoanDetailAfterRepay(
    loanDetailBefore
  );

  expectEqual(reserveDataAfter, expectedReserveData);
  expectEqual(creditLineAfter, expectedCreditLineData);
  expectEqual(loanDetailAfter, expectedLoanDetailData);
};

// todo current try to liquidate itself, try using a different user instead
export const liquidate = async (
  cname: string,
  loan: string,
  userIndex: number,
  expected: string,
  testEnv: TestEnv
) => {
  const collection = testEnv.collections.get(cname);
  const user = testEnv.users[userIndex];
  const vault = testEnv.vaults.get(user.address);
  const ownerBefore = await getOwnerOf(collection!, '1');

  if (expected != 'success') {
    await expect(
      testEnv.voyage.liquidate(collection!, vault!, loan)
    ).to.be.revertedWithCustomError(testEnv.voyage, expected);
    const ownerAfter = await getOwnerOf(collection!, '1');
    expectEqual(ownerBefore, ownerAfter);
    expectEqual(ownerAfter, vault!);
    return;
  }

  const txResult = await (
    await testEnv.voyage.liquidate(collection!, vault!, loan)
  ).wait();

  const loanDetailAfter = await getLoanDetail(
    testEnv.voyage,
    collection!,
    vault!,
    loan
  );

  const loanDetailEmpty = calcEmptyLoanDetail();
  expectEqual(loanDetailAfter, loanDetailEmpty);

  const ownerAfter = await getOwnerOf(collection!, '1');
  expectEqual(ownerAfter, user.address);
};

export const approve = async (
  tranche: string,
  amount: string,
  testEnv: TestEnv
) => {
  if (tranche == Tranche.Junior.toString()) {
    await (
      await testEnv.juniorDepositToken.approve(testEnv.voyage.address, amount)
    ).wait();
  } else {
    await (
      await testEnv.seniorDepositToken.approve(testEnv.voyage.address, amount)
    ).wait();
  }
};

export const mine = async (days: number) => {
  const daysToIncreased = days * 24 * 60 * 60;
  await ethers.provider.send('evm_increaseTime', [daysToIncreased]);
  await ethers.provider.send('evm_mine', []);
};

export const mint = async (
  cname: string,
  vault: string,
  tokenId: string,
  testEnv: TestEnv
) => {
  const Crab = await ethers.getContractFactory('Crab');
  const crabAddress = testEnv.collections.get(cname);
  const crab = Crab.attach(crabAddress!);
  await crab.safeMint(vault, tokenId);
};

export const getTxCostAndTimestamp = async (tx: ContractReceipt) => {
  if (!tx.blockNumber || !tx.transactionHash || !tx.cumulativeGasUsed) {
    throw new Error('No tx blocknumber');
  }
  const txTimestamp = BigNumber.from(
    (await hre.ethers.provider.getBlock(tx.blockNumber)).timestamp
  );

  const txInfo = await hre.ethers.provider.getTransaction(tx.transactionHash);
  const gasPrice = txInfo.gasPrice ? txInfo.gasPrice : tx.effectiveGasPrice;
  const txCost = BigNumber.from(tx.cumulativeGasUsed).mul(gasPrice);

  return { txCost, txTimestamp };
};

export const getContractsData = async (
  collection: string,
  user: string,
  testEnv: TestEnv
) => {
  const dataProviderFacet = testEnv.voyage;
  const vault = testEnv.vaults.get(user)!;
  const [reserveData, userData, creditLine, timestamp] = await Promise.all([
    getReserveData(dataProviderFacet, collection),
    getUserPoolData(dataProviderFacet, collection, user),
    getCreditLine(dataProviderFacet, collection, vault),
    timeLatest(),
  ]);
  return { reserveData, userData, creditLine, timestamp };
};

export const timeLatest = async () => {
  const block = await hre.ethers.provider.getBlock('latest');
  return BigNumber.from(block.timestamp);
};

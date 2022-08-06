import { BigNumber, ContractReceipt } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TestEnv } from './make-suite';
import {
  caclExpectedCreditLineDataAfterRepay,
  caclExpectedReserveDataAfterRepay,
  caclExpectedReserveDataAfterWithdraw,
  calcExpectedCreditLineAfterBorrow,
  calcExpectedReserveDataAfterBorrow,
  calcExpectedReserveDataAfterDeposit,
  calcExpectedUserDataAfterDeposit,
} from './utils/calculations';
import {
  getCreditLine,
  getLoanDetail,
  getPoolConfiguration,
  getReserveData,
  getUserPoolData,
} from './utils/helpers';
import {
  CreditLineData,
  ReserveData,
  Tranche,
  UserReserveData,
} from './utils/interfaces';
import chai from 'chai';
import { toWad } from '../../helpers/math';

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
  actual: UserReserveData | ReserveData | CreditLineData,
  expected: UserReserveData | ReserveData | CreditLineData
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
  console.log('collection: ', collection!);
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

export const borrow = async (
  cname: string,
  tokenId: string,
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

  const assetPrice = toWad(10);
  await testEnv.priceOracle.updateTwap(collection!, assetPrice);
  const txResult = await (
    await testEnv.voyage
      .connect(user.signer)
      .buyNow(collection!, tokenId, vault!, testEnv.purchaseData)
  ).wait();

  const { txCost, txTimestamp } = await getTxCostAndTimestamp(txResult);

  const {
    reserveData: reserveDataAfter,
    userData: userDataAfter,
    creditLine: creditLineAfter,
    timestamp,
  } = await getContractsData(collection!, user.address, testEnv);

  const expectedReserveData = calcExpectedReserveDataAfterBorrow(
    assetPrice.toString(),
    reserveDataBefore
  );

  const expectedCreditLineData = calcExpectedCreditLineAfterBorrow(
    assetPrice.toString(),
    creditLineBefore
  );
  expectEqual(reserveDataAfter, expectedReserveData);
  expectEqual(creditLineAfter, expectedCreditLineData);
};

export const repay = async (cname: string, loan: string, testEnv: TestEnv) => {
  const collection = testEnv.collections.get(cname);
  const user = testEnv.users[0];
  const vault = testEnv.vaults.get(user.address);

  const {
    reserveData: reserveDataBefore,
    userData: userDataBefore,
    creditLine: creditLineBefore,
  } = await getContractsData(collection!, user.address, testEnv);

  const loanDetail = await getLoanDetail(
    testEnv.voyage,
    collection!,
    vault!,
    loan
  );

  const poolConfg = await getPoolConfiguration(testEnv.voyage, collection!);
  const incomeRatio = poolConfg.incomeRatio;

  const txResult = await (
    await testEnv.voyage.repay(collection!, '0', vault!)
  ).wait();

  const {
    reserveData: reserveDataAfter,
    userData: userDataAfter,
    creditLine: creditLineAfter,
  } = await getContractsData(collection!, user.address, testEnv);

  const expectedReserveData = await caclExpectedReserveDataAfterRepay(
    loanDetail.principal.div(loanDetail.nper),
    loanDetail.interest.div(loanDetail.nper),
    incomeRatio,
    reserveDataBefore
  );

  const expectedCreditLineData = await caclExpectedCreditLineDataAfterRepay(
    loanDetail.principal.div(loanDetail.nper),
    creditLineBefore
  );
  expectEqual(reserveDataAfter, expectedReserveData);
  expectEqual(creditLineAfter, expectedCreditLineData);
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

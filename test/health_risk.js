const { expect } = require('chai');
const { DefaultHealthStrategy } = require('../typechain');
const { BigNumberish, BigNumber } = require('ethers');

const RAY = '1000000000000000000000000000';
const HALF_RAY = '500000000000000000000000000';

let healthStrategy;

describe('Health Strategy', function () {
  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    const HealthStrategy = await ethers.getContractFactory(
      'DefaultHealthStrategy'
    );
    healthStrategy = await HealthStrategy.deploy(RAY, 10, HALF_RAY, HALF_RAY);
  });

  it('Calculate health risk should return correct value', async function () {
    const rayNum = BigNumber.from(RAY);

    // 1. risk == 1 (initial status)
    const param0 = {
      // 100
      securityDeposit: '100000000000000000000000000000',
      // 10%
      currentBorrowRate: '100000000000000000000000000',
      compoundedDebt: '0',
      grossAssetValue: '0',
      aggregateOptimalRepaymentRate: '0',
      aggregateActualRepaymentRate: '0',
    };
    const riskInRay0 = await healthStrategy.calculateHealthRisk(param0);
    expect(riskInRay0).to.equal(rayNum);

    // 2. risk == 1
    const param1 = {
      // 100
      securityDeposit: '100000000000000000000000000000',
      // 10%
      currentBorrowRate: '100000000000000000000000000',
      // 1000
      compoundedDebt: '1000000000000000000000000000000',
      grossAssetValue: '900000000000000000000000000000',
      // 100
      aggregateOptimalRepaymentRate: '100000000000000000000000000000',
      aggregateActualRepaymentRate: '100000000000000000000000000000',
    };
    const riskInRay1 = await healthStrategy.calculateHealthRisk(param1);
    expect(riskInRay1).to.equal(rayNum);

    // 3. risk > 1
    const param2 = {
      // 200
      securityDeposit: '200000000000000000000000000000',
      // 10%
      currentBorrowRate: '100000000000000000000000000',
      // 1000
      compoundedDebt: '1000000000000000000000000000000',
      grossAssetValue: '900000000000000000000000000000',
      // 100
      aggregateOptimalRepaymentRate: '100000000000000000000000000000',
      aggregateActualRepaymentRate: '100000000000000000000000000000',
    };
    const riskInRay2 = await healthStrategy.calculateHealthRisk(param2);
    expect(riskInRay2.toString()).to.equal('1050000000000000000000000000');

    // 4. risk < 1
    const param3 = {
      // 200
      securityDeposit: '200000000000000000000000000000',
      // 10%
      currentBorrowRate: '100000000000000000000000000',
      // 1000
      compoundedDebt: '10000000000000000000000000000000',
      grossAssetValue: '500000000000000000000000000000',
      // 100
      aggregateOptimalRepaymentRate: '100000000000000000000000000000',
      aggregateActualRepaymentRate: '100000000000000000000000000000',
    };
    const riskInRay3 = await healthStrategy.calculateHealthRisk(param3);
    expect(riskInRay3.toString()).to.equal('535000000000000000000000000');
  });
});

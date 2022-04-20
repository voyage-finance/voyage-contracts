const { expect } = require('chai');
const {DefaultHealthStrategy} = require("../typechain");
const {BigNumberish, BigNumber} = require("ethers");

const RAY = '1000000000000000000000000000';
const HALF_RAY = '500000000000000000000000000';

let healthStrategy;

describe('Health Strategy', function () {
    beforeEach(async function () {
        [owner] = await ethers.getSigners();
        const HealthStrategy = await ethers.getContractFactory('DefaultHealthStrategy');
        healthStrategy = await HealthStrategy.deploy(RAY, 10, HALF_RAY, HALF_RAY);
    });

    it('Calculate health risk should return correct value', async function () {
        const param = {
            // 100
            securityDeposit: '100000000000000000000000000000',
            // 10%
            currentBorrowRate: '100000000000000000000000000',
            // 1000
            compoundedDebt: '1000000000000000000000000000000',
            grossAssetValue: '900000000000000000000000000000',
            // 100
            aggregateOptimalRepaymentRate: '100000000000000000000000000000',
            aggregateActualRepaymentRate: '100000000000000000000000000000'
        }
        const riskInRay = await healthStrategy.calculateHealthRisk(param);
        console.log(riskInRay.toString());
        // 100000000000000000000000000
        const rayNum = BigNumber.from(RAY);
        const risk = riskInRay.div(rayNum);
        console.log(risk.toString());

    });

})
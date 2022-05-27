import { expect } from 'chai';
import { setupDebtTestSuite } from '../helpers/debt';
import { BigNumber } from 'ethers';

describe('Lib Financial', function () {
  it('pmt function should return correct value', async function () {
    //  >>> npf.pmt(0.075/12, 12*15, 200000)
    //     -1854.0247200054619
    const { libFinancial } = await setupDebtTestSuite();
    const rateRay = BigNumber.from(75)
      .mul(BigNumber.from('1000000000000000000000000000'))
      .div(1000)
      .div(12);
    const pmt =
      (await libFinancial.pmt(
        rateRay,
        12 * 15,
        BigNumber.from('200000000000000000000000')
      )) / 1e18;
    console.log('pmt: ', pmt.toPrecision(10));
  });

  it('pmt function with adjusted APR should return correct value', async function () {
    const { libFinancial } = await setupDebtTestSuite();
    const rateRay = BigNumber.from(2067)
      .mul(BigNumber.from('1000000000000000000000000000'))
      .div(10000)
      .div(12);
    const pmt = await libFinancial.pmt(
      rateRay,
      3,
      BigNumber.from('300000000000000000000000')
    );
    console.log('pmt: ', pmt.toString());
  });

  it('fv function should return correct value', async function () {
    const { libFinancial } = await setupDebtTestSuite();
    const rateRay = BigNumber.from(5)
      .mul(BigNumber.from('1000000000000000000000000000'))
      .div(100)
      .div(12);
    const fv =
      (await libFinancial.fv(
        rateRay,
        12 * 10,
        BigNumber.from('100000000000000000000'),
        BigNumber.from('100000000000000000000')
      )) / 1e18;
    expect(fv.toPrecision(10)).to.equal('15692.92889');
  });

  it('fv function with rate 0.06/12 should return correct value', async function () {
    const { libFinancial } = await setupDebtTestSuite();
    const rateRay = BigNumber.from(6)
      .mul(BigNumber.from('1000000000000000000000000000'))
      .div(100)
      .div(12);
    const fv =
      (await libFinancial.fv(
        rateRay,
        12 * 10,
        BigNumber.from('100000000000000000000'),
        BigNumber.from('100000000000000000000')
      )) / 1e18;
    expect(fv.toPrecision(10)).to.equal('16569.87435');
  });

  it('ipmt and ppmt function should return correct value', async function () {
    const { libFinancial } = await setupDebtTestSuite();
    const rateRay = BigNumber.from(8)
      .mul(BigNumber.from('1000000000000000000000000000'))
      .div(100)
      .div(12);
    let principal = BigNumber.from('2500000000000000000000');
    for (let i = 1; i < 13; i++) {
      const ipmt = (await libFinancial.ipmt(rateRay, i, 12, principal)) / 1e18;
      const ppmt = (await libFinancial.ppmt(rateRay, i, 12, principal)) / 1e18;
      console.log(
        'ipmt: ',
        ipmt.toPrecision(10),
        'ppmt: ',
        ppmt.toPrecision(10)
      );
    }
  });

  it('ipmt and ppmt function with adjusted APR should return correct value', async function () {
    const { libFinancial } = await setupDebtTestSuite();
    const rateRay = BigNumber.from(2067)
      .mul(BigNumber.from('1000000000000000000000000000'))
      .div(10000)
      .div(12);
    let principal = BigNumber.from('300000000000000000000000');
    for (let i = 1; i < 4; i++) {
      const ipmt = (await libFinancial.ipmt(rateRay, i, 3, principal)) / 1e18;
      const ppmt = (await libFinancial.ppmt(rateRay, i, 3, principal)) / 1e18;
      console.log(
        'ipmt: ',
        ipmt.toPrecision(10),
        'ppmt: ',
        ppmt.toPrecision(10)
      );
    }
  });
});

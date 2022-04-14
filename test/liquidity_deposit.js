const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { ethers, deployments, getNamedAccounts } = require('hardhat');

let owner;
let voyager;
let tus;
let escrowContract;
let juniorDepositToken;
let seniorDepositToken;

describe('Reserve Deposit', function () {
  beforeEach(async function () {
    ({ owner } = await getNamedAccounts());
    await deployments.fixture([
      'AddressResolver',
      'Voyager',
      'LiquidityManager',
      'LiquidityManagerStorage',
      'Tokenization',
    ]);
    voyager = await ethers.getContract('Voyager');
    tus = await ethers.getContract('Tus');
    juniorDepositToken = await ethers.getContract('JuniorDepositToken');
    seniorDepositToken = await ethers.getContract('SeniorDepositToken');

    const reserveFlags = await voyager.getReserveFlags(tus.address);
    expect(reserveFlags[0]).to.equal(true);
    expect(reserveFlags[1]).to.equal(false);
    expect(reserveFlags[2]).to.equal(false);

    escrowContract = await voyager.getLiquidityManagerEscrowContractAddress();
    await tus.increaseAllowance(escrowContract, '100000000000000000000');
  });

  it('Deposit junior liquidity should return correct value', async function () {
    const depositAmount = '1000000000000000000';
    await voyager.deposit(tus.address, 0, depositAmount, owner);
    const juniorTokenAmount = await juniorDepositToken.balanceOf(owner);
    expect(juniorTokenAmount).to.equal(BigNumber.from(depositAmount));
    expect(await tus.balanceOf(escrowContract)).to.equal(
      BigNumber.from(depositAmount)
    );

    expect(await voyager.liquidityRate(tus.address, '0')).to.equal('0');
    // deposit again
    await voyager.deposit(tus.address, 0, depositAmount, owner);
    expect(await voyager.liquidityRate(tus.address, '0')).to.equal('0');
  });

  it('Deposit senior liquidity should return correct value', async function () {
    const depositAmount = '1000000000000000000';
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    const seniorTokenAmount = await seniorDepositToken.balanceOf(owner);
    expect(seniorTokenAmount).to.equal(BigNumber.from(depositAmount));

    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
    // deposit again
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
  });
});

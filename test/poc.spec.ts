import { JuniorDepositToken, SeniorDepositToken, WETH9 } from '@contracts';
import { REFUND_GAS_PRICE, REFUND_GAS_UNIT } from '@helpers/constants';
import { MAX_UINT_256 } from '@helpers/math';
import { setupTestSuite } from '@helpers/setupTestSuite';
import { getWETH9 } from '@helpers/task-helpers/addresses';
import { Tranche } from '@helpers/types';
import {
  LooksRareExchangeAbi,
  MakerOrderWithVRS,
  TakerOrderWithEncodedParams,
} from '@looksrare/sdk';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('an attacker should not be able to steal NFTs by abusing withdraw/claim', async () => {
  it('should be able to withdraw Principal + Interest correctly', async () => {
    const {
      crab,
      owner,
      alice,
      bob,
      voyage,
      priceOracle,
      marketPlace,
      weth,
      juniorDepositToken,
      seniorDepositToken,
      reserveConfiguration,
    } = await setupTestSuite();

    await dumpState(
      'Initial state',
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      undefined
    );

    /* ----------- cause Alice to deposit 6k ETH to the senior tranche ----------- */
    // deposit 3k ETH to junior
    const initialJuniorDeposit = ethers.utils.parseEther('10000');
    // deposit 6k ETH to senior
    const initialSeniorDeposit = ethers.utils.parseEther('6000');
    // alice will do the deposit.
    const aSigner = await ethers.getSigner(alice);
    await weth
      .connect(aSigner)
      .deposit({ value: ethers.utils.parseEther('20000') });
    await weth.connect(aSigner).approve(voyage.address, MAX_UINT_256);
    const aVoyage = voyage.connect(aSigner);
    console.log('alice deposit to junior tranche');
    await aVoyage.deposit(crab.address, 0, initialJuniorDeposit, {
      from: alice,
    });
    expect(await voyage.balance(crab.address, alice, Tranche.Junior)).to.equal(
      initialJuniorDeposit
    );
    expect(await juniorDepositToken.totalAssets()).to.equal(
      initialJuniorDeposit
    );
    console.log('alice deposit to senior tranche');
    await aVoyage.deposit(crab.address, 1, initialSeniorDeposit, {
      from: alice,
    });
    expect(await voyage.balance(crab.address, alice, Tranche.Senior)).to.equal(
      initialSeniorDeposit
    );
    expect(await seniorDepositToken.totalAssets()).to.equal(
      initialSeniorDeposit
    );

    await dumpState(
      'State after Alice deposits',
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      undefined
    );

    /* ----------------- have Bob purchase an NFT valued at 9ETH ---------------- */
    const bSigner = await ethers.getSigner(bob);
    const salt = ethers.utils
      .keccak256(ethers.utils.toUtf8Bytes('bob@voyage.finance'))
      .slice(0, 42);
    const computedVaultAddress = await voyage.computeCounterfactualAddress(
      bob,
      salt
    );
    // fund vault for first payment
    const tx = {
      to: computedVaultAddress,
      value: ethers.utils.parseEther('1000'),
    };
    const ownerSigner = await ethers.getSigner(owner);
    const createReceipt = await ownerSigner.sendTransaction(tx);
    await createReceipt.wait();
    console.log('create vault for bob');
    await voyage.createVault(bob, salt, REFUND_GAS_UNIT, REFUND_GAS_PRICE);
    const bVaultAddress = await voyage.getVault(bob);
    console.log('vault address: ', bVaultAddress);
    const bWeth = weth.connect(bSigner);
    await bSigner.sendTransaction({
      to: bVaultAddress,
      value: ethers.utils.parseEther('100'),
    });
    await bWeth.deposit({ value: ethers.utils.parseEther('100000') });
    await bWeth.transfer(bVaultAddress, ethers.utils.parseEther('1060'));
    await bWeth.approve(bVaultAddress, MAX_UINT_256);
    console.log('setup twap');
    await priceOracle.updateTwap(crab.address, ethers.utils.parseEther('3000'));

    const provider = new ethers.providers.AlchemyProvider(
      'rinkeby',
      process.env.RINKEBY_API_KEY
    );
    const looks = new ethers.Contract(
      '0x1AA777972073Ff66DCFDeD85749bDD555C0665dA',
      LooksRareExchangeAbi,
      provider
    );
    const looksRareMakerOrderData: MakerOrderWithVRS = {
      isOrderAsk: true,
      signer: '0xAc786F3E609eeBC3830A26881bd026B6b9211ae2',
      collection: crab.address,
      price: ethers.utils.parseEther('3000'), // 9 ETH value
      tokenId: '1',
      amount: 1,
      strategy: '0x732319A3590E4fA838C111826f9584a9A2fDEa1a',
      currency: await getWETH9(),
      nonce: ethers.constants.Zero,
      startTime: 1661852317,
      endTime: 1662457076,
      minPercentageToAsk: 9800,
      params: ethers.utils.defaultAbiCoder.encode([], []),
      v: 27,
      r: '0x66f2bf329cf885420596359ed1b435ef3ffe3b35efcbf10854b393724482369b',
      s: '0x6db5028edf4f90eba89576e8181a4b4051ae9053b08b0dfb5c0fd6c580b73f66',
    };
    const looksRareTakerOrderData: TakerOrderWithEncodedParams = {
      isOrderAsk: false,
      taker: bVaultAddress,
      price: looksRareMakerOrderData.price,
      tokenId: looksRareMakerOrderData.tokenId,
      minPercentageToAsk: 9800,
      params: ethers.utils.defaultAbiCoder.encode([], []),
    };
    const calldata = (
      await looks.populateTransaction.matchAskWithTakerBidUsingETHAndWETH(
        looksRareTakerOrderData,
        looksRareMakerOrderData
      )
    ).data!;

    const bVoyage = voyage.connect(bSigner);

    // approve marketplace
    bVoyage.approveMarketplace(bVaultAddress, marketPlace.address, false);

    await dumpState(
      'Before buy',
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      bVaultAddress
    );

    // buy
    console.log('bob buyNow');
    await bVoyage.buyNow(
      crab.address,
      1,
      bVaultAddress,
      marketPlace.address,
      calldata
    );
    await dumpState(
      'After buy',
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      bVaultAddress
    );

    /* ----------------- have Bob deposit a large amount of WETH ---------------- */
    await bWeth.deposit({ value: ethers.utils.parseEther('1000000') });
    await dumpState(
      "Before Bob's deposit",
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      bVaultAddress
    );
    await bWeth.approve(voyage.address, MAX_UINT_256);
    // deposit ~10x totalAssets()
    const bDeposit = ethers.utils.parseEther('1000000');
    await bVoyage.deposit(crab.address, 1, bDeposit);
    await dumpState(
      "After Bob's deposit",
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      bVaultAddress
    );

    /* --------------------- have Bob repay both instalments -------------------- */
    const loan = await voyage.getLoanDetail(bVaultAddress, crab.address, 0);
    const pmtPrincipal = loan.pmt.principal;
    const pmtInterest = loan.pmt.interest;
    await bWeth.transfer(bVaultAddress, ethers.utils.parseEther('2300'));
    await bVoyage.repay(crab.address, 0, bVaultAddress);
    await dumpState(
      'After repay 1',
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      bVaultAddress
    );

    await bVoyage.repay(crab.address, 0, bVaultAddress);
    await dumpState(
      'After repay 2',
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      bVaultAddress
    );

    /* ----------------------- have Bob withdraw his WETH ----------------------- */
    expect(await weth.balanceOf(seniorDepositToken.address)).to.equal(
      initialSeniorDeposit
        .add(bDeposit)
        .add(pmtInterest.mul(3).percentMul(reserveConfiguration.incomeRatio))
    );
    const bBalance0 = await seniorDepositToken.maxWithdraw(bob);

    await seniorDepositToken
      .connect(bSigner)
      .approve(voyage.address, MAX_UINT_256);
    await bVoyage.withdraw(crab.address, 1, bBalance0);
    await dumpState(
      'After withdraw',
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      bVaultAddress
    );

    /* ----------------------------- have Bob claim ----------------------------- */
    const wethBalance0 = await weth.balanceOf(bob);
    await seniorDepositToken.connect(bSigner).claim();
    const wethBalance1 = await weth.balanceOf(bob);
    const totalClaimed = wethBalance1.sub(wethBalance0);
    expect(totalClaimed).to.equal(bBalance0);
    await dumpState(
      'After claim',
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      bVaultAddress
    );
  });
});

async function dumpState(
  event: string,
  weth: WETH9,
  juniorDepositToken: JuniorDepositToken,
  seniorDepositToken: SeniorDepositToken,
  alice: string,
  bob: string,
  bVaultAddress: string | undefined
) {
  console.log('------- ' + event + ' ------');
  // Junior pool state
  console.log(
    'Junior WETH balance: ',
    ethers.utils.formatEther(await weth.balanceOf(juniorDepositToken.address))
  );
  console.log(
    'Junior totalAssets(): ',
    ethers.utils.formatEther(await juniorDepositToken.totalAssets())
  );

  // Senior pool state
  console.log(
    'Senior WETH balance: ',
    ethers.utils.formatEther(await weth.balanceOf(seniorDepositToken.address))
  );
  console.log(
    'Senior totalAssets(): ',
    ethers.utils.formatEther(await seniorDepositToken.totalAssets())
  );

  // Alice state
  console.log(
    'Alice WETH balance: ',
    ethers.utils.formatEther(await weth.balanceOf(alice))
  );
  console.log(
    'Alice junior withdrawable balance: ',
    ethers.utils.formatEther(await juniorDepositToken.maxWithdraw(alice))
  );
  console.log(
    'Alice senior withdrawable balance: ',
    ethers.utils.formatEther(await seniorDepositToken.maxWithdraw(alice))
  );

  // Bob state
  console.log(
    'Bob WETH balance: ',
    ethers.utils.formatEther(await weth.balanceOf(bob))
  );
  console.log(
    'Bob junior withdrawable balance: ',
    ethers.utils.formatEther(await juniorDepositToken.maxWithdraw(bob))
  );
  console.log(
    'Bob senior withdrawable balance: ',
    ethers.utils.formatEther(await seniorDepositToken.maxWithdraw(bob))
  );
  if (bVaultAddress !== undefined) {
    console.log(
      'Bob vault WETH balance: ',
      ethers.utils.formatEther(await weth.balanceOf(bVaultAddress))
    );
  }
}

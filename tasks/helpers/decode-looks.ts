import { LooksRareExchangeAbi } from '@looksrare/sdk';
import { task } from 'hardhat/config';

task('dev:decode-looks', 'Decodes the given LooksRare calldata')
  .addParam('calldata', 'The calldata to decode')
  .setAction(async (params, hre) => {
    const { ethers } = hre;
    await hre.run('set-hre');
    const looks = new ethers.Contract(
      ethers.constants.AddressZero,
      LooksRareExchangeAbi,
      ethers.provider
    );
    const decoded = looks.interface.decodeFunctionData(
      'matchAskWithTakerBidUsingETHAndWETH',
      params.calldata
    );
    console.log('decoded calldata:\n\n');
    const { makerAsk, takerBid } = decoded;
    console.log({
      takerBid: {
        isOrderAsk: takerBid.isOrderAsk,
        taker: takerBid.taker,
        price: ethers.utils.formatEther(takerBid.price),
        tokenId: takerBid.tokenId.toString(),
        minPercentageToAsk: takerBid.minPercentageToAsk.toString(),
        params: takerBid.params,
      },
      makerAsk: {
        isOrderAsk: makerAsk.isOrderAsk,
        signer: makerAsk.signer,
        collection: makerAsk.collection,
        price: ethers.utils.formatEther(makerAsk.price),
        tokenId: makerAsk.tokenId.toString(),
        amount: ethers.utils.formatEther(makerAsk.amount),
        strategy: makerAsk.strategy,
        currency: makerAsk.currency,
        nonce: makerAsk.nonce.toString(),
        startTime: makerAsk.startTime.toString(),
        endTime: makerAsk.endTime.toString(),
        minPercentageToAsk: makerAsk.minPercentageToAsk.toString(),
        params: makerAsk.params,
        v: makerAsk.v,
        r: makerAsk.r,
        s: makerAsk.s,
      },
    });
  });

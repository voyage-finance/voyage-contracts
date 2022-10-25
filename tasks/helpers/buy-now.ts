import { Voyage } from "@contracts";
import {
    LooksRareExchangeAbi,
    MakerOrderWithVRS,
    TakerOrderWithEncodedParams,
} from "@looksrare/sdk";
import { task, types } from "hardhat/config";

task(
    "dev:mock-buy-now",
    "Invokes buy-now on the **mock** marketplace (looks ABI)."
)
    .addOptionalParam(
        "collection",
        "The collection to buy. Defaults to Mocked Crab."
    )
    .addOptionalParam(
        "tokenId",
        "The token ID to use in the maker order",
        1,
        types.int
    )
    .addOptionalParam(
        "price",
        "The price of the maker order in ETH",
        "0.1",
        types.string
    )
    .addOptionalParam("vault", "The target vault. Defaults to owner vault.")
    .setAction(async (params, hre) => {
        await hre.run("set-hre");
        const { ethers } = hre;
        const mc = await hre.ethers.getContract("Crab");
        const mp = await hre.ethers.getContract("MockMarketPlace");
        const { owner, alice } = await hre.getNamedAccounts();
        const voyage = await hre.ethers.getContract<Voyage>("Voyage");
        const ownerVault = await voyage.getVault(owner);
        const {
            vault = ownerVault,
            collection = mc.address,
            tokenId,
            price,
        } = params;
        const makerOrder: MakerOrderWithVRS = {
            isOrderAsk: true,
            signer: alice,
            collection,
            price: hre.ethers.utils.parseEther(price),
            tokenId: tokenId.toString(),
            amount: 1,
            strategy: "0x732319A3590E4fA838C111826f9584a9A2fDEa1a",
            currency: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
            nonce: hre.ethers.constants.Zero,
            startTime: 1661852317,
            endTime: 1662457076,
            minPercentageToAsk: 9800,
            params: hre.ethers.utils.defaultAbiCoder.encode([], []),
            v: 27,
            r: "0x66f2bf329cf885420596359ed1b435ef3ffe3b35efcbf10854b393724482369b",
            s: "0x6db5028edf4f90eba89576e8181a4b4051ae9053b08b0dfb5c0fd6c580b73f66",
        };
        const takerOrder: TakerOrderWithEncodedParams = {
            isOrderAsk: false,
            taker: vault,
            price: makerOrder.price,
            tokenId: makerOrder.tokenId,
            minPercentageToAsk: 9800,
            params: hre.ethers.utils.defaultAbiCoder.encode([], []),
        };
        const looks = new ethers.Contract(
            ethers.constants.AddressZero,
            LooksRareExchangeAbi,
            ethers.provider
        );
        const { data } =
            await looks.populateTransaction.matchAskWithTakerBidUsingETHAndWETH(
                takerOrder,
                makerOrder
            );

        const tx = await voyage.buyNow(
            collection,
            tokenId,
            vault,
            mp.address,
            data!
        );
        const receipt = await tx.wait();
        console.log(
            `Purchased tokenId ${tokenId} from collection ${collection} with vault ${vault} for ${price}`
        );
        console.log(`Transaction hash: ${receipt.transactionHash}`);
    });

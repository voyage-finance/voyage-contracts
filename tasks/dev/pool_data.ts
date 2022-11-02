import { Voyage } from "@contracts";
import { task} from "hardhat/config";

task("dev:pool-data", "Get pool data.")
    .addOptionalParam(
        "collection",
        "The collections to check."
    )
    .setAction(async (params, hre) => {
        await hre.run("set-hre");
        const { ethers } = hre;
        const {
            collection
        } = params;
        const voyage = await ethers.getContract<Voyage>("Voyage");
        const poolData = await voyage.getPoolData(collection);
        console.log("pool data: ", poolData);
    });

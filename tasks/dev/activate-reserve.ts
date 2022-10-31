import { Voyage } from "@contracts";
import { task } from "hardhat/config";

task("dev:activate-reserve", "Deactivate a reserve.")
    .addOptionalParam(
        "collection",
        "The collections to deactivate."
    )
    .setAction(async (params, hre) => {
        await hre.run("set-hre");
        const { ethers } = hre;
        const {
            collection
        } = params;
        const voyage = await ethers.getContract<Voyage>("Voyage");
        await voyage.activateReserve(collection).then((tx) => tx.wait());
    });

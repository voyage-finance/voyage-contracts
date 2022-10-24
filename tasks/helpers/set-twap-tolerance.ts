import { Voyage } from "@contracts";
import { task, types } from "hardhat/config";

task("dev:set-twap-tolerance", "Sets the twap tolerance")
    .addOptionalParam("collection", "Address of the collection to set.")
    .addOptionalParam(
        "tolerance",
        "Tolerance percent value",
        2000, // 20%
        types.int
    )
    .setAction(async (params, hre) => {
        await hre.run("set-hre");
        const { ethers } = hre;
        const voyage = await ethers.getContract<Voyage>("Voyage");
        const mc = await ethers.getContract("Crab");
        const { collection = mc.address, tolerance } = params;
        console.log(
            `setting twap tollerance for ${collection} to ${tolerance}`
        );
        const tx = await voyage.setTwapTolerance(collection, tolerance);
        await tx.wait();
        const res = await voyage.getTwapTolerance(collection);
        console.log("twap tolerance: ", res.toString());
    });

import { Voyage } from "@contracts";
import { task } from "hardhat/config";
import { getTwapSigner } from "@helpers/task-helpers/addresses";

task("dev:configure-oracle-signer", "Sets the oracle message signer for twap")
    .addOptionalParam("signer", "Address of twap message signer address")
    .setAction(async (params, hre) => {
        await hre.run("set-hre");
        const { ethers } = hre;
        const oracleSigner = await getTwapSigner();
        console.log("oracleSigner ", oracleSigner);
        const voyage = await ethers.getContract<Voyage>("Voyage");
        const tx = await voyage.setOracleSigner(oracleSigner);
        await tx.wait();
        console.log(`set oracle signer to ${oracleSigner}`);
    });

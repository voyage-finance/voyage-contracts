import { log } from "@helpers/logger";
import { task, types } from "hardhat/config";

task("deploy:dev", "Deploys a development environment, including mocks")
    .addOptionalParam(
        "tags",
        "Comma-separated tags to pass to hardhat-deploy",
        undefined,
        types.string
    )
    .setAction(async (params, hre) => {
        await hre.run("set-hre");
        log.info("Starting migration.");
        await hre.run("deploy", {
            ...params,
            reportGas: true,
        });
        const gasUsed = hre.deployments.getGasUsed();
        const deploymentCost = hre.ethers.utils
            .parseUnits("5", "gwei")
            .mul(gasUsed);
        log.info(
            `Cost of deployment: ${hre.ethers.utils.formatEther(
                deploymentCost
            )} ETH`
        );

        log.info("Configuring marketplace adapters");
        await hre.run("dev:configure-marketplace-adapters");

        log.info("Configuring Vault implementation");
        await hre.run("dev:configure-vault-impl");

        log.info("Configuring GSN");
        await hre.run("dev:configure-gsn");

        log.info("Configuring Junior Deposit Token implementation");
        await hre.run("dev:configure-jd-impl");

        log.info("Configuring Senior Deposit Token implementation");
        await hre.run("dev:configure-sd-impl");

        log.info("Configuring Oracle Signer for TWAP");
        await hre.run("dev:configure-oracle-signer");
    });

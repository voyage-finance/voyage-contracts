import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import * as tdly from "@tenderly/hardhat-tenderly";
import "hardhat-diamond-abi";
import "@typechain/hardhat";
import { config as dotenvConfig } from "dotenv";
import { ethers } from "ethers";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import "hardhat-prettier";
import "hardhat-watcher";
import { HardhatUserConfig } from "hardhat/types";
import { resolve } from "path";
import "tsconfig-paths/register";
import "hardhat-ignore-warnings";

if (process.env.SKIP_TASKS !== "true") {
    require("./tasks/helpers");
    require("./tasks/dev");
    require("./tasks/migration");
}

dotenvConfig({ path: resolve(__dirname, "./.env") });

tdly.setup({ automaticVerifications: process.env.TENDERLY === "true" });

const HARDHAT_MNEMONIC =
    process.env.HARDHAT_MNEMONIC ||
    "test test test test test test test test test test test junk";

const MAINNET_MNEMONIC = process.env.MAINNET_MNEMONIC || "";

const HARDHAT_CHAIN_ID = process.env.HARDHAT_CHAIN_ID
    ? parseInt(process.env.HARDHAT_CHAIN_ID)
    : 31337;

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

const cov = process.env.COVERAGE === "true";
if (cov) {
    require("solidity-coverage");
}

const reportGas = process.env.REPORT_GAS === "true";

const TENDERLY_CHAIN_ID = parseInt(process.env.TENDERLY_CHAIN_ID ?? "1");
const TENDERLY_FORK_URL = process.env.TENDERLY_FORK_URL ?? "";

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    networks: {
        // configuration is for tenderly.
        localhost: {
            chainId: HARDHAT_CHAIN_ID,
            url: "http://127.0.0.1:8545",
        },
        hardhat: {
            chainId: HARDHAT_CHAIN_ID,
            allowUnlimitedContractSize: false,
            accounts: {
                mnemonic: HARDHAT_MNEMONIC,
                accountsBalance: ethers.utils
                    .parseEther("10000000000000000000000")
                    .toString(),
            },
            mining:
                process.env.MINING_MODE !== "interval"
                    ? { auto: true }
                    : {
                          interval: parseInt(
                              process.env.MIN_INTERVAL || "500",
                              10
                          ),
                      },
        },
        tenderly: {
            chainId: TENDERLY_CHAIN_ID,
            url: TENDERLY_FORK_URL,
            accounts: {
                mnemonic: process.env.TENDERLY_MNEMONIC,
            },
        },
        goerli: {
            chainId: 5,
            url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_GOERLI_API_KEY}`,
            accounts: {
                mnemonic: process.env.GOERLI_MNEMONIC,
            },
        },
        mainnet: {
            chainId: 1,
            url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_MAINNET_API_KEY}`,
            accounts: {
                mnemonic: MAINNET_MNEMONIC,
            },
        },
    },
    watcher: {
        test: {
            tasks: ["test"],
            files: ["./contracts", "./test"],
        },
        compile: {
            tasks: ["compile"],
        },
    },
    namedAccounts: {
        // deployer/owner signer can now be accessed as accounts[0]
        owner: 0,
        alice: 1,
        bob: 2,
        treasury: 9,
        forwarder: 10,
    },
    diamondAbi: [
        {
            name: "Voyage",
            include: [
                "contracts/voyage/facets",
                "contracts/shared/diamond/facets",
            ],
        },
    ],
    solidity: {
        compilers: [
            {
                version: "0.8.9",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 2000,
                    },
                },
            },
        ],
    },
    tenderly: {
        project: "protocol-v1",
        username: "voyage-finance",
        privateVerification: true,
    },
    etherscan: {
        apiKey: {
            mainnet: ETHERSCAN_API_KEY,
            goerli: ETHERSCAN_API_KEY,
        },
    },
    gasReporter: {
        enabled: reportGas,
        currency: "USD",
        token: "ETH",
        // TODO: regenerate key before going to prd
        coinmarketcap: "49d8a069-b7bf-4a9e-8cb4-dc9c19bff806",
    },
    typechain: {
        outDir: "contract-types",
        target: "ethers-v5",
    },
    warnings: {
        'contracts/mock/**/*': {
            default: 'off',
        },
    }
};

export default config;

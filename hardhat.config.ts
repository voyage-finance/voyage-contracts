import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';
import { ethers } from 'ethers';
import { task } from 'hardhat/config';
import { HardhatUserConfig } from 'hardhat/types';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import 'hardhat-gas-reporter';
import 'hardhat-prettier';
import 'hardhat-deploy';
import 'solidity-coverage';

dotenvConfig({ path: resolve(__dirname, './.env') });

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || '';
// TODO @ian.tan these transactions should at some point be signed by a ledger in production.
const DEPLOYER_PRIVATE_KEY =
  process.env.DEPLOYER_PRIVATE_KEY || ethers.Wallet.createRandom().privateKey;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.getAddress());
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      mining:
        process.env.MINING_MODE !== 'interval'
          ? { auto: true }
          : {
              interval: parseInt(process.env.MIN_INTERVAL || '2000', 10),
            },
    },
    avalancheMain: {
      // TODO @ian.tan use a private node!
      url: 'https://api.avax.network/ext/bc/C/rpc',
      chainId: 43114,
      accounts: [DEPLOYER_PRIVATE_KEY],
    },
    avalancheFuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      chainId: 43113,
      accounts: [DEPLOYER_PRIVATE_KEY],
      gas: 8000000,
    },
    voyage: {
      url: 'https://vethtest.staging.voyage.finance/',
      chainId: 666,
      accounts: [DEPLOYER_PRIVATE_KEY],
      gas: 20000000,
    },
  },
  namedAccounts: {
    // deployer/owner signer can now be accessed as accounts[0]
    owner: 0,
  },
  solidity: {
    compilers: [
      {
        version: '0.6.12',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
        },
      },
      {
        version: '0.6.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
        },
      },
      {
        version: '0.8.4',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
        },
      },
      {
        version: '0.8.9',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
        },
      },
    ],
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 100,
    // enabled: process.env.REPORT_GAS ? true : false,
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5',
  },
};

if (!process.env.AUTOMINE) {
}

export default config;

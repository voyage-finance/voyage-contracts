import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';
import { ethers } from 'ethers';
import { task } from 'hardhat/config';
import { HardhatUserConfig } from 'hardhat/types';
import 'hardhat-diamond-abi';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import 'hardhat-gas-reporter';
import 'hardhat-prettier';
import 'hardhat-deploy';
import 'hardhat-watcher';

dotenvConfig({ path: resolve(__dirname, './.env') });

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || '';
// TODO @ian.tan these transactions should at some point be signed by a ledger in production.
const DEPLOYER_PRIVATE_KEY =
  process.env.DEPLOYER_PRIVATE_KEY || ethers.Wallet.createRandom().privateKey;

const cov = process.env.COVERAGE === 'true';
if (cov) {
  require('solidity-coverage');
}

const reportGas = process.env.GAS_REPORT === 'true';

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (_, hre) => {
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
      allowUnlimitedContractSize: false,
      mining:
        process.env.MINING_MODE !== 'interval'
          ? { auto: true }
          : {
              interval: parseInt(process.env.MIN_INTERVAL || '500', 10),
            },
    },
    avalancheMain: {
      url: 'https://avax-c.staging.voyage.finance/rpc',
      chainId: 43114,
      accounts: [DEPLOYER_PRIVATE_KEY],
    },
    avalancheFuji: {
      url: 'https://fuji-c.staging.voyage.finance/rpc',
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
  watcher: {
    test: {
      tasks: ['test'],
      files: ['./contracts', './test'],
    },
    compile: {
      tasks: ['compile'],
    },
  },
  namedAccounts: {
    // deployer/owner signer can now be accessed as accounts[0]
    owner: 0,
    alice: 1,
    bob: 2,
  },
  diamondAbi: {
    name: 'Voyager',
    include: ['contracts/component/facets'],
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
    enabled: reportGas,
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5',
  },
};

export default config;

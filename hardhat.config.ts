import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@nomicfoundation/hardhat-chai-matchers';
import * as tdly from '@tenderly/hardhat-tenderly';
import 'hardhat-diamond-abi';
import '@typechain/hardhat';
import { config as dotenvConfig } from 'dotenv';
import 'hardhat-deploy';
import 'hardhat-gas-reporter';
import 'hardhat-prettier';
import 'hardhat-watcher';
import 'tsconfig-paths/register';
import { task } from 'hardhat/config';
import { HardhatUserConfig } from 'hardhat/types';
import { resolve } from 'path';
import { ethers } from 'ethers';

if (process.env.SKIP_TASKS !== 'true') {
  require('./tasks/helpers');
  require('./tasks/dev');
}

dotenvConfig({ path: resolve(__dirname, './.env') });

tdly.setup({ automaticVerifications: process.env.TENDERLY === 'true' });

const HARDHAT_MNEMONIC =
  process.env.HARDHAT_MNEMONIC ||
  'test test test test test test test test test test test junk';

const HARDHAT_CHAIN_ID = process.env.HARDHAT_CHAIN_ID
  ? parseInt(process.env.HARDHAT_CHAIN_ID)
  : 31337;

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || '';

const cov = process.env.COVERAGE === 'true';
if (cov) {
  require('solidity-coverage');
}

const reportGas = process.env.REPORT_GAS === 'true';

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
    // configuration is for tenderly.
    localhost: {
      chainId: HARDHAT_CHAIN_ID,
      url: 'http://127.0.0.1:8545',
    },
    hardhat: {
      chainId: HARDHAT_CHAIN_ID,
      allowUnlimitedContractSize: false,
      accounts: {
        mnemonic: HARDHAT_MNEMONIC,
        accountsBalance: ethers.utils
          .parseEther('10000000000000000')
          .toString(),
      },
      mining:
        process.env.MINING_MODE !== 'interval'
          ? { auto: true }
          : {
              interval: parseInt(process.env.MIN_INTERVAL || '500', 10),
            },
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_GOERLI_API_KEY}`,
      accounts: {
        mnemonic: process.env.GOERLI_MNEMONIC,
      },
    },
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_RINKEBY_API_KEY}`,
      accounts: {
        mnemonic: process.env.GOERLI_MNEMONIC,
      },
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
    treasury: 9,
    forwarder: 10,
  },
  diamondAbi: [
    {
      name: 'Voyage',
      include: ['contracts/voyage/facets', 'contracts/shared/diamond/facets'],
    },
  ],
  solidity: {
    compilers: [
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
  tenderly: {
    project: 'protocol-v1',
    username: 'voyage-finance',
    privateVerification: true,
  },
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
      rinkeby: ETHERSCAN_API_KEY,
    },
  },
  gasReporter: {
    enabled: reportGas,
    currency: 'USD',
    token: 'ETH',
    // TODO: regenerate key before going to prd
    coinmarketcap: '49d8a069-b7bf-4a9e-8cb4-dc9c19bff806',
  },
  typechain: {
    outDir: 'contract-types',
    target: 'ethers-v5',
  },
};

export default config;

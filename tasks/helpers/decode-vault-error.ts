import { task } from 'hardhat/config';
import { LooksRareExchangeAbi } from '@looksrare/sdk';

task('dev:decode-vault-error', 'Decode Vault error')
  .addParam('message', 'Message of the error')
  .setAction(async (params, hre) => {
    // 5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c6564
    const { message } = params;
    const output = Buffer.from(message, 'hex');
    console.log(message + ' -> ' + output);
  });

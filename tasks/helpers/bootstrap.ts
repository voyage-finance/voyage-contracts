import { Voyage, WETH9 } from '@contracts';
import { Tranche } from '@helpers/types';
import { task, types } from 'hardhat/config';

task('dev:bootstrap', 'Bootstraps a reserve, vault, and user balances')
  .addOptionalParam(
    'collection',
    'The collection to use to bootstrap the reserve. Defaults to Mocked Crab.'
  )
  .addOptionalParam(
    'user',
    'The user to create a vault for, and fund with WETH. Defaults to first account of mnemonic.'
  )
  .addOptionalParam(
    'balance',
    'Amount to fund the user in WETH.',
    '1000000',
    types.string
  )
  .addOptionalParam(
    'seniorTrancheBalance',
    'Amount to fund the senior tranche for, in WETH.',
    '50000',
    types.string
  )
  .addOptionalParam(
    'juniorTrancheBalance',
    'Amount to fund the junior tranche for, in WETH.',
    '10000',
    types.string
  )
  .addOptionalParam(
    'vaultBalance',
    'Amount to fund the user vault with',
    '10000',
    types.string
  )
  .setAction(async (params, hre) => {
    const { ethers, getNamedAccounts, run } = hre;
    await hre.run('set-hre');
    const defaultCollection = await ethers.getContract('Crab');
    const { owner: defaultUser } = await getNamedAccounts();
    const {
      collection = defaultCollection.address,
      user = defaultUser,
      balance,
      seniorTrancheBalance,
      juniorTrancheBalance,
      vaultBalance,
    } = params;

    console.log('Setting up markeptlace adapters');
    await run('dev:configure-marketplace-adapters');

    console.log(`Creating/initializing reserve for collection ${collection}`);
    await run('dev:initialize-reserve', { collection });

    console.log(`Funding user ${user} with ${balance} WETH`);
    const weth = await ethers.getContract<WETH9>('WETH9');
    const targetBalance = ethers.utils.parseEther(balance);
    const wethBalance = await weth.balanceOf(user);
    if (wethBalance.lt(targetBalance)) {
      const wethDeposit = targetBalance.sub(wethBalance);
      await run('dev:deposit-weth', {
        amount: ethers.utils.formatEther(wethDeposit),
        sender: user,
      });
    }

    console.log(`Depositing ${juniorTrancheBalance} into junior tranche\n`);
    await run('dev:deposit-reserve', {
      reserve: collection,
      tranche: Tranche.Junior,
      amount: juniorTrancheBalance,
      sender: user,
    });
    console.log(`Depositing ${seniorTrancheBalance} into senior tranche\n`);
    await run('dev:deposit-reserve', {
      reserve: collection,
      tranche: Tranche.Senior,
      amount: seniorTrancheBalance,
      sender: user,
    });

    console.log(`Wrapping WETH for user ${user}\n`);
    await run('dev:deposit-weth', { sender: user });

    console.log(`Approving Voyage to spend WETH for ${user}\n`);
    await run('dev:approve-weth', { approver: user });

    console.log(`Creating vault for user ${user}\n`);
    await run('dev:create-vault', { user });

    const voyage = await ethers.getContract<Voyage>('Voyage');
    const vaultAddress = await voyage.getVault(user);
    console.log(
      `Funding the vault ${vaultAddress} for ${user} for ${vaultBalance}\n`
    );
    await run('dev:fund-vault', {
      amount: vaultBalance,
      sender: user,
      sendeth: true,
    });
  });

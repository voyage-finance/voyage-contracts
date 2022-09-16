import { Tranche } from '@helpers/types';
import { task, types } from 'hardhat/config';

task('dev:bootstrap', 'Bootstraps a reserve, vault, and user balances')
  .addOptionalParam(
    'collection',
    'The collection to use to bootstrap the reserve. Defaults to Mocked Crab.'
  )
  .addOptionalParam(
    'sender',
    'The address to use to fund the reserve. Defaults to first account of mnemonic.'
  )
  .addOptionalParam(
    'senior',
    'Amount to fund the senior tranche for, in WETH.',
    '50000',
    types.string
  )
  .addOptionalParam(
    'junior',
    'Amount to fund the junior tranche for, in WETH.',
    '10000',
    types.string
  )
  .addOptionalParam('floor', 'Amount to set TWAP to.', '0.5', types.string)
  .setAction(async (params, hre) => {
    const { ethers, getNamedAccounts, run } = hre;
    await hre.run('set-hre');
    const defaultCollection = await ethers.getContract('Crab');
    const { owner: defaultUser } = await getNamedAccounts();
    const {
      collection = defaultCollection.address,
      sender = defaultUser,
      senior,
      junior,
      floor,
    } = params;

    console.log(
      `Creating/initializing reserve for collection ${collection}.\n`
    );
    await run('dev:initialize-reserve', { collection, floorPrice: floor });

    console.log(`Approving Voyage to spend WETH for sender ${sender}\n`);
    await run('dev:approve-weth', { approver: sender });

    console.log(`Depositing ${junior} into junior tranche\n`);
    await run('dev:deposit-reserve', {
      reserve: collection,
      tranche: Tranche.Junior,
      amount: junior,
      sender,
    });
    console.log(`Depositing ${senior} into senior tranche\n`);
    await run('dev:deposit-reserve', {
      reserve: collection,
      tranche: Tranche.Senior,
      amount: senior,
      sender,
    });
  });

import { task } from 'hardhat/config';

task('dev:get-hub', 'Gets the paymaster hub address')
  .addOptionalParam(
    'paymaster',
    'The address of the paymaster. Defaults to VoyagePaymaster.'
  )
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const defaultPaymaster = await ethers.getContract('VoyagePaymaster');
    const paymaster = params.paymaster
      ? await ethers.getContractAt('VoyagePaymaster', params.paymaster)
      : defaultPaymaster;
    const hubAddr = await paymaster.getHubAddr();
    console.log(`${paymaster.address} has ${hubAddr} set as RelayHub.`);
  });

import { setMarketplaceAdapters } from '@helpers/task-helpers/configuration';
import { getMarketplaceAdapterConfiguration } from '@helpers/task-helpers/contracts';
import { task } from 'hardhat/config';

task(
  'dev:configure-marketplace-adapters',
  'Sets marketplace adapters to latest deployment.'
)
  .addFlag('disableMock', 'Whether or not to disable mock marketplace.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const adapterConfiguration = await getMarketplaceAdapterConfiguration();
    if (!params.disableMock) {
      const mockMarketplace = await hre.ethers.getContract('MockMarketPlace');
      const looksAdapter = await hre.ethers.getContract('LooksRareAdapter');
      adapterConfiguration.push({
        marketplace: mockMarketplace.address,
        adapter: looksAdapter.address,
      });
    }
    await setMarketplaceAdapters(adapterConfiguration);
  });

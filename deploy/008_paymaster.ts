import { log } from '@helpers/logger';
import {
  getRelayHub,
  getTreasury,
  getTrustedForwarder,
  getWETH9,
} from '@helpers/task-helpers/addresses';
import { DeployFunction } from 'hardhat-deploy/types';

const main: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();
  const weth9 = await getWETH9();
  const treasury = await getTreasury();
  const voyage = await ethers.getContract('Voyage');
  const paymaster = await deploy('VoyagePaymaster', {
    from: owner,
    log: true,
    args: [voyage.address, weth9, treasury],
  });

  if (paymaster.newlyDeployed) {
    const forwarder = await getTrustedForwarder();
    await execute(
      'VoyagePaymaster',
      { from: owner, log: true },
      'setTrustedForwarder',
      forwarder
    );
    log.info('set paymaster forwarder to %s', forwarder);

    const relayHub = await getRelayHub();
    await execute(
      'VoyagePaymaster',
      { from: owner, log: true },
      'setRelayHub',
      relayHub
    );
    log.info('set paymaster relay hub to %s', relayHub);
  }
};

main.tags = ['Paymaster'];
main.dependencies = ['Diamond', 'Facets'];

export default main;

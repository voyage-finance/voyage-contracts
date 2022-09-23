import { log } from '@helpers/logger';
import { task } from 'hardhat/config';

task(
  'deploy:dev',
  'Deploys a development environment, including mocks'
).setAction(async (_, hre) => {
  await hre.run('set-hre');
  log.info('Starting migration.');
  await hre.run('deploy');

  log.info('Configuring marketplace adapters');
  await hre.run('dev:configure-marketplace-adapters');

  log.info('Configuring Vault implementation');
  await hre.run('dev:configure-vault-impl');

  log.info('Configuring GSN');
  await hre.run('dev:configure-gsn');

  log.info('Configuring Junior Deposit Token implementation');
  await hre.run('dev:configure-jd-impl');

  log.info('Configuring Senior Deposit Token implementation');
  await hre.run('dev:configure-sd-impl');
});

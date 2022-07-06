import { DeployFunction } from 'hardhat-deploy/types';
import { MockMarketPlace, Tus, Vault } from '@contracts';
import { Crab } from '@contracts';
import BigNumber from 'bignumber.js';

const WRM_NAME = 'WadRayMath';
const INTEREST_STRATEGY_NAME = 'DefaultReserveInterestRateStrategy';

const RAY = new BigNumber(10).pow(27);

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();

  const tusSupply = new BigNumber(1_000_000_000_000).multipliedBy(
    new BigNumber(10).pow(18)
  );
  if (network.name !== 'avalancheMain') {
    await deploy('Tus', {
      from: owner,
      log: true,
      args: [tusSupply.toFixed()],
    });
    await deploy('Crab', {
      from: owner,
      log: true,
      args: ['Mocked Crab', 'MC'],
    });
    await deploy('MockCrabadaBattleGame', {
      from: owner,
      log: true,
    });
  }
  const voyage = await deployments.get('Voyage');
  const tus = await ethers.getContract<Tus>('Tus');
  const crab = await ethers.getContract<Crab>('Crab');
  await deploy('MockMarketPlace', {
    from: owner,
    log: true,
    args: [tus.address, crab.address, 0, owner],
  });
  const mp = await ethers.getContract<MockMarketPlace>('MockMarketPlace');
  const battle_game = await ethers.getContract('MockCrabadaBattleGame');
  await deploy('CrabadaExternalAdapter', {
    from: owner,
    log: true,
    args: [
      voyage.address,
      crab.address,
      tus.address,
      mp.address,
      battle_game.address,
    ],
  });
  const strategy = await ethers.getContract<Crab>('CrabadaExternalAdapter');

  await execute(
    'Voyage',
    { from: owner, log: true },
    'setVaultStrategyAddr',
    tus.address,
    strategy.address
  );
  await execute(
    'Voyage',
    { from: owner, log: true },
    'setVaultStrategyAddr',
    crab.address,
    strategy.address
  );
  await execute(
    'Voyage',
    { from: owner, log: true },
    'setVaultStrategyAddr',
    mp.address,
    strategy.address
  );
  await execute(
    'Voyage',
    { from: owner, log: true },
    'setVaultStrategyAddr',
    battle_game.address,
    strategy.address
  );

  const wadRayMath = await deploy(WRM_NAME, { from: owner, log: true });

  const utilisationRate = new BigNumber('0.8').multipliedBy(RAY).toFixed();
  const slope1 = new BigNumber('0.04').multipliedBy(RAY).toFixed();
  const slope2 = new BigNumber('1').multipliedBy(RAY).toFixed();
  const baseInterest = new BigNumber('0.18').multipliedBy(RAY).toFixed();

  await deploy(INTEREST_STRATEGY_NAME, {
    from: owner,
    log: true,
    libraries: { WadRayMath: wadRayMath.address },
    args: [utilisationRate, slope1, slope2, baseInterest],
  });
};

deployFn.dependencies = ['Voyage'];
deployFn.tags = ['Tokenization'];

export default deployFn;
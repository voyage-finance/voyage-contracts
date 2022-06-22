import { DeployFunction } from 'hardhat-deploy/types';
import { Tus } from '@contracts';
import BigNumber from 'bignumber.js';
import { MAX_UINT_256 } from '../helpers/math';

const JR_TOKEN_NAME = 'JuniorDepositToken';
const SR_TOKEN_NAME = 'SeniorDepositToken';
const WRM_NAME = 'WadRayMath';
const INTEREST_STRATEGY_NAME = 'DefaultReserveInterestRateStrategy';

const RAY = new BigNumber(10).pow(27);

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute, read } = deployments;
  const { owner } = await getNamedAccounts();

  const tusSupply = new BigNumber(1_000_000_000_000).multipliedBy(
    new BigNumber(10).pow(18)
  );
  if (!network.live && network.name !== 'avalancheMain') {
    await deploy('Tus', {
      from: owner,
      log: true,
      args: [tusSupply.toFixed()],
    });
  }
  const tus = await ethers.getContract<Tus>('Tus');
  const AddressResolver = await deployments.get('AddressResolver');
  const voyager = await deployments.get('Voyager');
  const JuniorDepositToken = await deploy(JR_TOKEN_NAME, {
    from: owner,
    log: true,
    args: [voyager.address, tus.address, 'TUS Junior Tranche', 'jvTUS'],
  });
  const SeniorDepositToken = await deploy(SR_TOKEN_NAME, {
    from: owner,
    log: true,
    args: [voyager.address, tus.address, 'TUS Senior Tranche', 'svTUS'],
  });

  await execute(
    'Voyager',
    { from: owner, log: true },
    'approve',
    tus.address,
    SeniorDepositToken.address,
    MAX_UINT_256
  );
  await execute(
    'Voyager',
    { from: owner, log: true },
    'approve',
    tus.address,
    JuniorDepositToken.address,
    MAX_UINT_256
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

  const names = [
    ethers.utils.formatBytes32String('juniorDepositToken'),
    ethers.utils.formatBytes32String('seniorDepositToken'),
  ];
  const destinations = [JuniorDepositToken.address, SeniorDepositToken.address];
  await execute(
    'AddressResolver',
    { from: owner, log: true },
    'importAddresses',
    names,
    destinations
  );
};

deployFn.dependencies = ['AddressResolver', 'Voyager'];
deployFn.tags = ['Tokenization'];

export default deployFn;

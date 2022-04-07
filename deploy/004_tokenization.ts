import { DeployFunction } from 'hardhat-deploy/types';
import { LiquidityManager, Tus } from '../typechain';
import TusABI from '../artifacts/contracts/mock/Tus.sol/Tus.json';

const LM_NAME = 'LiquidityManager';
const LM_STORAGE_NAME = 'LiquidityManagerStorage';
const JR_TOKEN_NAME = 'JuniorDepositToken';
const SR_TOKEN_NAME = 'SeniorDepositToken';
const DEBT_TOKEN_NAME = 'StableDebtToken';
const WRM_NAME = 'WadRayMath';
const INTEREST_STRAT_NAME = 'DefaultReserveInterestRateStrategy';

const WAD = 1000000000000000000;

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute, read } = deployments;
  const { owner } = await getNamedAccounts();
  const signer = ethers.provider.getSigner(0);

  let TreasureUnderSea: Tus;
  if (network.live && network.name === 'avalancheMain') {
    TreasureUnderSea = new ethers.Contract(
      process.env.TUS || '0x0',
      TusABI.abi,
      signer
    ) as Tus;
  } else {
    const TusDeployment = await deploy('Tus', {
      from: owner,
      log: true,
      args: [(BigInt(1000) * BigInt(WAD)).toString()],
    });
    TreasureUnderSea = new ethers.Contract(
      TusDeployment.address,
      TusDeployment.abi,
      signer
    ) as Tus;
  }
  const tusInitArgs = await Promise.all([
    TreasureUnderSea.address,
    TreasureUnderSea.decimals(),
    TreasureUnderSea.name(),
    TreasureUnderSea.symbol(),
  ]);
  const AddressResolver = await deployments.get('AddressResolver');
  const JuniorDepositToken = await deploy(JR_TOKEN_NAME, {
    from: owner,
    log: true,
  });
  const SeniorDepositToken = await deploy(SR_TOKEN_NAME, {
    from: owner,
    log: true,
  });

  if (!(await read(JR_TOKEN_NAME, 'isInitialized'))) {
    await execute(
      JR_TOKEN_NAME,
      { from: owner, log: true },
      'initialize',
      AddressResolver.address,
      ...tusInitArgs,
      ethers.utils.formatBytes32String('')
    );
  }

  if (!(await read(SR_TOKEN_NAME, 'isInitialized'))) {
    await execute(
      SR_TOKEN_NAME,
      { from: owner, log: true },
      'initialize',
      AddressResolver.address,
      ...tusInitArgs,
      ethers.utils.formatBytes32String('')
    );
  }

  const StableDebtToken = await deploy('StableDebtToken', {
    from: owner,
    log: true,
  });
  if (!(await read(DEBT_TOKEN_NAME, 'isInitialized'))) {
    await execute(
      DEBT_TOKEN_NAME,
      { from: owner, log: true },
      'initialize',
      ...tusInitArgs,
      ethers.utils.formatBytes32String('')
    );
  }

  const WadRayMath = await deploy(WRM_NAME, { from: owner, log: true });
  const InterestStrategy = await deploy(INTEREST_STRAT_NAME, {
    from: owner,
    log: true,
    libraries: { WadRayMath: WadRayMath.address },
    // 50% 10% 20% 8%
    args: [
      '500000000000000000000000000',
      '100000000000000000000000000',
      '200000000000000000000000000',
      '80000000000000000000000000',
    ],
  });
  await execute(
    'Voyager',
    { from: owner, log: true },
    'initReserve',
    TreasureUnderSea.address,
    JuniorDepositToken.address,
    SeniorDepositToken.address,
    '100000000000000000000000000',
    '900000000000000000000000000',
    StableDebtToken.address,
    InterestStrategy.address
  );
};

deployFn.dependencies = [
  'AddressResolver',
  'Voyager',
  LM_NAME,
  LM_STORAGE_NAME,
];
deployFn.tags = ['Tokenization'];

export default deployFn;

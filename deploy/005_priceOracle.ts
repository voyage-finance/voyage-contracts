import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const PRICE_ORACLE = 'PriceOracle';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute, read } = deployments;
  const { owner } = await getNamedAccounts();
  const signer = ethers.provider.getSigner(0);

  const Voyager = await deployments.get('Voyager');
  const PriceOracle = await deploy(PRICE_ORACLE, {
    from: owner,
    args: [Voyager.address],
    log: true,
  });

  const names = [ethers.utils.formatBytes32String('priceOracle')];
  const destinations = [PriceOracle.address];

  await execute(
    'AddressResolver',
    { from: owner, log: true },
    'importAddresses',
    names,
    destinations
  );
};

deployFn.dependencies = ['AddressResolver', 'Voyager'];
deployFn.tags = ['PriceOracle'];

export default deployFn;

import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const PRICE_ORACLE = 'PriceOracle';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute, read } = deployments;
  const { owner } = await getNamedAccounts();
  const signer = ethers.provider.getSigner(0);

  const PriceOracle = await deploy(PRICE_ORACLE, {
    from: owner,
    log: true,
  });
};

deployFn.tags = ['PriceOracle'];

export default deployFn;

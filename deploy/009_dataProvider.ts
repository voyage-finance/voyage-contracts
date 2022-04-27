import { DeployFunction } from 'hardhat-deploy/types';
import { DefaultHealthStrategy, Tus } from '@contracts';
import TusABI from '../artifacts/contracts/mock/Tus.sol/Tus.json';
import { ethers } from 'hardhat';

const DATA_PROVIDER = 'VoyageProtocolDataProvider';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute, read } = deployments;
  const { owner } = await getNamedAccounts();
  const signer = ethers.provider.getSigner(0);

  const AddressResolver = await deployments.get('AddressResolver');

  const DataProvider = await deploy(DATA_PROVIDER, {
    from: owner,
    args: [AddressResolver.address],
    log: true,
  });
};

deployFn.dependencies = ['AddressResolver'];
deployFn.tags = ['VoyageProtocolDataProvider'];

export default deployFn;

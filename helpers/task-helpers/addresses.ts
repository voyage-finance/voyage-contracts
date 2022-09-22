import {
  FORWARDER_ADDRESS,
  RELAY_HUB_ADDRESS,
  TREASURY_ADDRESS,
  WETH_ADDRESS,
} from '@helpers/constants';
import { ChainID, ExternalChainID } from '@helpers/types';
import { isFork, isHardhat } from './chain';
import { HRE as hre } from './hre';

export async function getWETH9() {
  console.log('is hardhat: ', isHardhat());
  console.log('is fork: ', isFork());
  if (isHardhat() && !isFork()) {
    const { address } = await hre.ethers.getContract('WETH9');
    console.log('weth9 address: ', address);
    return address;
  }

  return WETH_ADDRESS[hre.network.config.chainId as ExternalChainID];
}

export async function getTreasury() {
  const { getNamedAccounts } = hre;
  if (isHardhat() && !isFork()) {
    const { treasury } = await getNamedAccounts();
    return treasury;
  }

  return TREASURY_ADDRESS[hre.network.config.chainId as ExternalChainID];
}

export async function getTrustedForwarder() {
  if (isHardhat() && !isFork()) {
    const { forwarder } = await hre.getNamedAccounts();
    return forwarder;
  }

  return FORWARDER_ADDRESS[hre.network.config.chainId as ExternalChainID];
}

export async function getRelayHub() {
  const { getNamedAccounts } = hre;
  if (isHardhat() && !isFork()) {
    const { forwarder } = await getNamedAccounts();
    return forwarder;
  }

  return RELAY_HUB_ADDRESS[hre.network.config.chainId as ExternalChainID];
}

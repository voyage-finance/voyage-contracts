import { HardhatRuntimeEnvironment } from 'hardhat/types';

export let HRE: HardhatRuntimeEnvironment;

export function setHRE(hre: HardhatRuntimeEnvironment) {
  HRE = hre;
}

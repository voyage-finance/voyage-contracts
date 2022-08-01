import { setupTestSuite } from '../../helpers/setupTestSuite';
import { Contract, Signer } from 'ethers';
import { ethers } from 'hardhat';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Tus } from 'typechain/Tus';
import { Voyage } from 'typechain/Voyage';

export type tEthereumAddress = string;

export interface SignerWithAddress {
  signer: Signer;
  address: tEthereumAddress;
}

export interface TestEnv {
  users: SignerWithAddress[];
  voyage: Voyage;
  tus: Tus;
  juniorDepositToken: Contract;
  seniorDepositToken: Contract;
  vault: string;

  collections: Map<string, string>;
  // user address => Vault
  // in case we need more vault in the furute
  vaults: Map<string, string>;
}

const testEnv: TestEnv = {
  users: [] as SignerWithAddress[],
  collections: new Map<string, string>(),
  vaults: new Map<string, string>(),
} as TestEnv;

export function makeSuite(name: string, tests: (testEnv: TestEnv) => void) {
  describe(name, () => {
    tests(testEnv);
  });
}

declare var hre: HardhatRuntimeEnvironment;

export async function initializeMakeSuite() {
  const { getNamedAccounts } = hre;
  const { owner } = await getNamedAccounts();
  const signer = await ethers.getSigner(owner);
  const {
    voyage,
    juniorDepositToken,
    seniorDepositToken,
    tus,
    crab,
    deployedVault,
  } = await setupTestSuite();
  testEnv.users.push({
    signer,
    address: owner,
  });
  testEnv.voyage = voyage;
  testEnv.juniorDepositToken = juniorDepositToken;
  testEnv.seniorDepositToken = seniorDepositToken;
  testEnv.vault = deployedVault;
  testEnv.collections.set('TUS', crab.address);
  testEnv.vaults.set(owner, deployedVault);
}

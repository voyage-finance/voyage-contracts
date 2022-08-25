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
  priceOracle: Contract;
  marketplace: Contract;
  purchaseData: string;
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
  const { owner, alice } = await getNamedAccounts();
  const signerOfOwner = await ethers.getSigner(owner);
  const signerOfAlice = await ethers.getSigner(alice);
  const {
    voyage,
    juniorDepositToken,
    seniorDepositToken,
    crab,
    deployedVault,
    priceOracle,
    purchaseDataFromLooksRare,
    marketPlace,
  } = await setupTestSuite();
  testEnv.users.push({
    signer: signerOfOwner,
    address: owner,
  });
  testEnv.users.push({
    signer: signerOfAlice,
    address: alice,
  });
  testEnv.voyage = voyage;
  testEnv.juniorDepositToken = juniorDepositToken;
  testEnv.seniorDepositToken = seniorDepositToken;
  testEnv.vault = deployedVault;
  testEnv.purchaseData = purchaseDataFromLooksRare;
  testEnv.priceOracle = priceOracle;
  testEnv.marketplace = marketPlace;
  testEnv.collections.set('crab', crab.address);
  testEnv.vaults.set(owner, deployedVault);
  // for negative case, alice does not  deployedVault
  testEnv.vaults.set(alice, deployedVault);
}

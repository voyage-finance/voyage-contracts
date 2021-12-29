/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type {
  ReentrancyGuard,
  ReentrancyGuardInterface,
} from "../ReentrancyGuard";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
];

const _bytecode =
  "0x6080604052348015600f57600080fd5b506001600081905550603f8060256000396000f3fe6080604052600080fdfea2646970667358221220ff96268f6fba462aa710d60b4377c8362ff2c615924f6864e1f2d71ac56e046364736f6c63430008090033";

export class ReentrancyGuard__factory extends ContractFactory {
  constructor(
    ...args: [signer: Signer] | ConstructorParameters<typeof ContractFactory>
  ) {
    if (args.length === 1) {
      super(_abi, _bytecode, args[0]);
    } else {
      super(...args);
    }
  }

  deploy(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ReentrancyGuard> {
    return super.deploy(overrides || {}) as Promise<ReentrancyGuard>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): ReentrancyGuard {
    return super.attach(address) as ReentrancyGuard;
  }
  connect(signer: Signer): ReentrancyGuard__factory {
    return super.connect(signer) as ReentrancyGuard__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ReentrancyGuardInterface {
    return new utils.Interface(_abi) as ReentrancyGuardInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ReentrancyGuard {
    return new Contract(address, _abi, signerOrProvider) as ReentrancyGuard;
  }
}
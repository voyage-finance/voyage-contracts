/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import { Provider } from "@ethersproject/providers";
import type { IVaultManager, IVaultManagerInterface } from "../IVaultManager";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "initialize",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export class IVaultManager__factory {
  static readonly abi = _abi;
  static createInterface(): IVaultManagerInterface {
    return new utils.Interface(_abi) as IVaultManagerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IVaultManager {
    return new Contract(address, _abi, signerOrProvider) as IVaultManager;
  }
}

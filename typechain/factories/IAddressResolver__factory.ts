/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import { Provider } from "@ethersproject/providers";
import type {
  IAddressResolver,
  IAddressResolverInterface,
} from "../IAddressResolver";

const _abi = [
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "name",
        type: "bytes32",
      },
    ],
    name: "getAddress",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "name",
        type: "bytes32",
      },
      {
        internalType: "string",
        name: "reason",
        type: "string",
      },
    ],
    name: "requireAndGetAddress",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

export class IAddressResolver__factory {
  static readonly abi = _abi;
  static createInterface(): IAddressResolverInterface {
    return new utils.Interface(_abi) as IAddressResolverInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IAddressResolver {
    return new Contract(address, _abi, signerOrProvider) as IAddressResolver;
  }
}

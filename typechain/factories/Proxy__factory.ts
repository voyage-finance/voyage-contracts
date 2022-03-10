/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Proxy, ProxyInterface } from "../Proxy";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "previousOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "contract Proxyable",
        name: "newTarget",
        type: "address",
      },
    ],
    name: "TargetUpdated",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "callData",
        type: "bytes",
      },
      {
        internalType: "uint256",
        name: "numTopics",
        type: "uint256",
      },
      {
        internalType: "bytes32",
        name: "topic1",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "topic2",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "topic3",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "topic4",
        type: "bytes32",
      },
    ],
    name: "_emit",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "claimOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "isOwner",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
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
    inputs: [],
    name: "pendingOwner",
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
        internalType: "contract Proxyable",
        name: "_target",
        type: "address",
      },
    ],
    name: "setTarget",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "target",
    outputs: [
      {
        internalType: "contract Proxyable",
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
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3610ae4806100db6000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c8063907dff971161005b578063907dff97146100ef578063d4b839921461010b578063e30c397814610129578063f2fde38b1461014757610088565b80634e71e0c81461008d578063776d1a01146100975780638da5cb5b146100b35780638f32d59b146100d1575b600080fd5b610095610163565b005b6100b160048036038101906100ac91906106e5565b6102ff565b005b6100bb6103c1565b6040516100c89190610721565b60405180910390f35b6100d96103e5565b6040516100e69190610757565b60405180910390f35b61010960048036038101906101049190610843565b61043c565b005b610113610594565b6040516101209190610951565b60405180910390f35b6101316105ba565b60405161013e9190610721565b60405180910390f35b610161600480360381019061015c9190610998565b6105e0565b005b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146101bd57600080fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff166000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b6103076103e5565b610346576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161033d90610a22565b60405180910390fd5b80600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055507f814250a3b8c79fcbe2ead2c131c952a278491c8f4322a79fe84b5040a810373e816040516103b69190610951565b60405180910390a150565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614905090565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146104cc576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016104c390610a8e565b60405180910390fd5b6000878790509050600088888080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509050866000811461054b57600181146105565760028114610562576003811461056f576004811461057d57610588565b8260208301a0610588565b868360208401a1610588565b85878460208501a2610588565b8486888560208601a3610588565b838587898660208701a45b50505050505050505050565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6105e86103e5565b610627576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161061e90610a22565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006106a082610675565b9050919050565b60006106b282610695565b9050919050565b6106c2816106a7565b81146106cd57600080fd5b50565b6000813590506106df816106b9565b92915050565b6000602082840312156106fb576106fa61066b565b5b6000610709848285016106d0565b91505092915050565b61071b81610695565b82525050565b60006020820190506107366000830184610712565b92915050565b60008115159050919050565b6107518161073c565b82525050565b600060208201905061076c6000830184610748565b92915050565b600080fd5b600080fd5b600080fd5b60008083601f84011261079757610796610772565b5b8235905067ffffffffffffffff8111156107b4576107b3610777565b5b6020830191508360018202830111156107d0576107cf61077c565b5b9250929050565b6000819050919050565b6107ea816107d7565b81146107f557600080fd5b50565b600081359050610807816107e1565b92915050565b6000819050919050565b6108208161080d565b811461082b57600080fd5b50565b60008135905061083d81610817565b92915050565b600080600080600080600060c0888a0312156108625761086161066b565b5b600088013567ffffffffffffffff8111156108805761087f610670565b5b61088c8a828b01610781565b9750975050602061089f8a828b016107f8565b95505060406108b08a828b0161082e565b94505060606108c18a828b0161082e565b93505060806108d28a828b0161082e565b92505060a06108e38a828b0161082e565b91505092959891949750929550565b6000819050919050565b600061091761091261090d84610675565b6108f2565b610675565b9050919050565b6000610929826108fc565b9050919050565b600061093b8261091e565b9050919050565b61094b81610930565b82525050565b60006020820190506109666000830184610942565b92915050565b61097581610695565b811461098057600080fd5b50565b6000813590506109928161096c565b92915050565b6000602082840312156109ae576109ad61066b565b5b60006109bc84828501610983565b91505092915050565b600082825260208201905092915050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b6000610a0c6020836109c5565b9150610a17826109d6565b602082019050919050565b60006020820190508181036000830152610a3b816109ff565b9050919050565b7f4d7573742062652070726f787920746172676574000000000000000000000000600082015250565b6000610a786014836109c5565b9150610a8382610a42565b602082019050919050565b60006020820190508181036000830152610aa781610a6b565b905091905056fea2646970667358221220d969e4bcdf58e09a1e4ae98f5317189ce49c9cb3a4c6b9279d37e5c10c499be064736f6c63430008090033";

export class Proxy__factory extends ContractFactory {
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
  ): Promise<Proxy> {
    return super.deploy(overrides || {}) as Promise<Proxy>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): Proxy {
    return super.attach(address) as Proxy;
  }
  connect(signer: Signer): Proxy__factory {
    return super.connect(signer) as Proxy__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ProxyInterface {
    return new utils.Interface(_abi) as ProxyInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Proxy {
    return new Contract(address, _abi, signerOrProvider) as Proxy;
  }
}
/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Main, MainInterface } from "../Main";

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
    inputs: [],
    name: "claimOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_reserve",
        type: "address",
      },
      {
        internalType: "uint8",
        name: "_underlyingAssetDecimals",
        type: "uint8",
      },
      {
        internalType: "address",
        name: "_interestRateStrategyAddress",
        type: "address",
      },
      {
        internalType: "enum Main.Tranche",
        name: "tranche",
        type: "uint8",
      },
    ],
    name: "initReserve",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_reserve",
        type: "address",
      },
      {
        internalType: "string",
        name: "_oTokenName",
        type: "string",
      },
      {
        internalType: "string",
        name: "_oTokenSymbol",
        type: "string",
      },
      {
        internalType: "uint8",
        name: "_underlyingAssetDecimals",
        type: "uint8",
      },
      {
        internalType: "address",
        name: "_interestRateStrategyAddress",
        type: "address",
      },
      {
        internalType: "enum Main.Tranche",
        name: "tranche",
        type: "uint8",
      },
    ],
    name: "initReserveWithData",
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
  "0x608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a36001600281905550610db5806100e36000396000f3fe608060405234801561001057600080fd5b506004361061007d5760003560e01c80638da5cb5b1161005b5780638da5cb5b146100c45780638f32d59b146100e2578063e30c397814610100578063f2fde38b1461011e5761007d565b8063078d0443146100825780634e71e0c81461009e5780637d003caa146100a8575b600080fd5b61009c60048036038101906100979190610762565b61013a565b005b6100a6610332565b005b6100c260048036038101906100bd919061090f565b6104ce565b005b6100cc610566565b6040516100d991906109e3565b60405180910390f35b6100ea61058a565b6040516100f79190610a19565b60405180910390f35b6101086105e1565b60405161011591906109e3565b60405180910390f35b61013860048036038101906101339190610a34565b610607565b005b3373ffffffffffffffffffffffffffffffffffffffff16600460009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16146101ca576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016101c190610ae4565b60405180910390fd5b600084905060008173ffffffffffffffffffffffffffffffffffffffff166306fdde036040518163ffffffff1660e01b815260040160006040518083038186803b15801561021757600080fd5b505afa15801561022b573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f820116820180604052508101906102549190610ba7565b6040516020016102649190610c83565b604051602081830303815290604052905060008273ffffffffffffffffffffffffffffffffffffffff166395d89b416040518163ffffffff1660e01b815260040160006040518083038186803b1580156102bd57600080fd5b505afa1580156102d1573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f820116820180604052508101906102fa9190610ba7565b60405160200161030a9190610cf1565b60405160208183030381529060405290506103298783838989896104ce565b50505050505050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461038c57600080fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff166000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b3373ffffffffffffffffffffffffffffffffffffffff16600460009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff161461055e576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161055590610ae4565b60405180910390fd5b505050505050565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614905090565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b61060f61058a565b61064e576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161064590610d5f565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b6000604051905090565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006106d1826106a6565b9050919050565b6106e1816106c6565b81146106ec57600080fd5b50565b6000813590506106fe816106d8565b92915050565b600060ff82169050919050565b61071a81610704565b811461072557600080fd5b50565b60008135905061073781610711565b92915050565b6002811061074a57600080fd5b50565b60008135905061075c8161073d565b92915050565b6000806000806080858703121561077c5761077b61069c565b5b600061078a878288016106ef565b945050602061079b87828801610728565b93505060406107ac878288016106ef565b92505060606107bd8782880161074d565b91505092959194509250565b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b61081c826107d3565b810181811067ffffffffffffffff8211171561083b5761083a6107e4565b5b80604052505050565b600061084e610692565b905061085a8282610813565b919050565b600067ffffffffffffffff82111561087a576108796107e4565b5b610883826107d3565b9050602081019050919050565b82818337600083830152505050565b60006108b26108ad8461085f565b610844565b9050828152602081018484840111156108ce576108cd6107ce565b5b6108d9848285610890565b509392505050565b600082601f8301126108f6576108f56107c9565b5b813561090684826020860161089f565b91505092915050565b60008060008060008060c0878903121561092c5761092b61069c565b5b600061093a89828a016106ef565b965050602087013567ffffffffffffffff81111561095b5761095a6106a1565b5b61096789828a016108e1565b955050604087013567ffffffffffffffff811115610988576109876106a1565b5b61099489828a016108e1565b94505060606109a589828a01610728565b93505060806109b689828a016106ef565b92505060a06109c789828a0161074d565b9150509295509295509295565b6109dd816106c6565b82525050565b60006020820190506109f860008301846109d4565b92915050565b60008115159050919050565b610a13816109fe565b82525050565b6000602082019050610a2e6000830184610a0a565b92915050565b600060208284031215610a4a57610a4961069c565b5b6000610a58848285016106ef565b91505092915050565b600082825260208201905092915050565b7f5468652063616c6c6572206d7573742062652061206c656e64696e6720706f6f60008201527f6c206d616e616765720000000000000000000000000000000000000000000000602082015250565b6000610ace602983610a61565b9150610ad982610a72565b604082019050919050565b60006020820190508181036000830152610afd81610ac1565b9050919050565b60005b83811015610b22578082015181840152602081019050610b07565b83811115610b31576000848401525b50505050565b6000610b4a610b458461085f565b610844565b905082815260208101848484011115610b6657610b656107ce565b5b610b71848285610b04565b509392505050565b600082601f830112610b8e57610b8d6107c9565b5b8151610b9e848260208601610b37565b91505092915050565b600060208284031215610bbd57610bbc61069c565b5b600082015167ffffffffffffffff811115610bdb57610bda6106a1565b5b610be784828501610b79565b91505092915050565b600081905092915050565b7f4f776e667420496e7465726573742062656172696e6720000000000000000000600082015250565b6000610c31601783610bf0565b9150610c3c82610bfb565b601782019050919050565b600081519050919050565b6000610c5d82610c47565b610c678185610bf0565b9350610c77818560208601610b04565b80840191505092915050565b6000610c8e82610c24565b9150610c9a8284610c52565b915081905092915050565b7f6100000000000000000000000000000000000000000000000000000000000000600082015250565b6000610cdb600183610bf0565b9150610ce682610ca5565b600182019050919050565b6000610cfc82610cce565b9150610d088284610c52565b915081905092915050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b6000610d49602083610a61565b9150610d5482610d13565b602082019050919050565b60006020820190508181036000830152610d7881610d3c565b905091905056fea26469706673582212207fc41280ca57d5cf64ae6e1c625f474345272962c7fbd4f1fd302317411dbeb264736f6c63430008090033";

export class Main__factory extends ContractFactory {
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
  ): Promise<Main> {
    return super.deploy(overrides || {}) as Promise<Main>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): Main {
    return super.attach(address) as Main;
  }
  connect(signer: Signer): Main__factory {
    return super.connect(signer) as Main__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MainInterface {
    return new utils.Interface(_abi) as MainInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Main {
    return new Contract(address, _abi, signerOrProvider) as Main;
  }
}

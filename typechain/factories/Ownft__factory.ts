/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import {
  Signer,
  utils,
  BigNumberish,
  Contract,
  ContractFactory,
  Overrides,
} from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Ownft, OwnftInterface } from "../Ownft";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "interest_rate",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
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
        name: "token",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "deposit",
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
        name: "token",
        type: "address",
      },
      {
        internalType: "bool",
        name: "enable",
        type: "bool",
      },
    ],
    name: "setDepositWhiteList",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "interest_rate",
        type: "uint256",
      },
    ],
    name: "setInterestRate",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
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
  "0x60806040523480156200001157600080fd5b506040516200188838038062001888833981810160405281019062000037919062000140565b336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3806004819055505062000172565b600080fd5b6000819050919050565b6200011a8162000105565b81146200012657600080fd5b50565b6000815190506200013a816200010f565b92915050565b60006020828403121562000159576200015862000100565b5b6000620001698482850162000129565b91505092915050565b61170680620001826000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c80638da5cb5b1161005b5780638da5cb5b146101135780638f32d59b14610131578063e30c39781461014f578063f2fde38b1461016d57610088565b80633c7660351461008d57806347e7ef24146100bd5780634e71e0c8146100d95780635f84f302146100e3575b600080fd5b6100a760048036038101906100a29190610dd6565b610189565b6040516100b49190610e2f565b60405180910390f35b6100d760048036038101906100d29190610e76565b610233565b005b6100e16103b2565b005b6100fd60048036038101906100f89190610eb6565b61054e565b60405161010a9190610e2f565b60405180910390f35b61011b6105a7565b6040516101289190610ef2565b60405180910390f35b6101396105cb565b6040516101469190610f1c565b60405180910390f35b610157610622565b6040516101649190610ef2565b60405180910390f35b61018760048036038101906101829190610f37565b610648565b005b60006101936105cb565b6101d2576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016101c990610fc1565b60405180910390fd5b81600260008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055506000905092915050565b60011515600260008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff161515146102c6576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016102bd9061102d565b60405180910390fd5b6000600360003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020905060008160010154111561035c57600061032d826001015460045484600201546106d3565b905061035a33828673ffffffffffffffffffffffffffffffffffffffff166107469092919063ffffffff16565b505b6103893330848673ffffffffffffffffffffffffffffffffffffffff166107cc909392919063ffffffff16565b8181600101600082825461039d919061107c565b92505081905550428160020181905550505050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461040c57600080fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff166000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b60006105586105cb565b610597576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161058e90610fc1565b60405180910390fd5b8160048190555060009050919050565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614905090565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6106506105cb565b61068f576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161068690610fc1565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b6000806106e9834261085590919063ffffffff16565b905060006107146106fd6301e133806108b4565b610706846108b4565b6108d490919063ffffffff16565b905061073b8661072d838861093290919063ffffffff16565b61093290919063ffffffff16565b925050509392505050565b6107c78363a9059cbb60e01b84846040516024016107659291906110d2565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050610997565b505050565b61084f846323b872dd60e01b8585856040516024016107ed939291906110fb565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050610997565b50505050565b60008282111561089a576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016108919061117e565b60405180910390fd5b600082846108a8919061119e565b90508091505092915050565b60006108cd633b9aca0083610a5e90919063ffffffff16565b9050919050565b6000806002836108e49190611201565b90506109298361091b61090c6b033b2e3c9fd0803ce800000088610a5e90919063ffffffff16565b84610ad990919063ffffffff16565b610b3790919063ffffffff16565b91505092915050565b600061098f6b033b2e3c9fd0803ce800000061098161095a8587610a5e90919063ffffffff16565b60026b033b2e3c9fd0803ce80000006109739190611201565b610ad990919063ffffffff16565b610b3790919063ffffffff16565b905092915050565b60006109f9826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c65648152508573ffffffffffffffffffffffffffffffffffffffff16610b959092919063ffffffff16565b9050600081511115610a595780806020019051810190610a199190611247565b610a58576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610a4f906112e6565b60405180910390fd5b5b505050565b600080831415610a715760009050610ad3565b60008284610a7f9190611306565b9050828482610a8e9190611201565b14610ace576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610ac5906113d2565b60405180910390fd5b809150505b92915050565b6000808284610ae8919061107c565b905083811015610b2d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b249061143e565b60405180910390fd5b8091505092915050565b6000808211610b7b576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b72906114aa565b60405180910390fd5b60008284610b899190611201565b90508091505092915050565b6060610ba48484600085610bad565b90509392505050565b606082471015610bf2576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610be99061153c565b60405180910390fd5b610bfb85610cc1565b610c3a576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610c31906115a8565b60405180910390fd5b6000808673ffffffffffffffffffffffffffffffffffffffff168587604051610c639190611642565b60006040518083038185875af1925050503d8060008114610ca0576040519150601f19603f3d011682016040523d82523d6000602084013e610ca5565b606091505b5091509150610cb5828286610cd4565b92505050949350505050565b600080823b905060008111915050919050565b60608315610ce457829050610d34565b600083511115610cf75782518084602001fd5b816040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610d2b91906116ae565b60405180910390fd5b9392505050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610d6b82610d40565b9050919050565b610d7b81610d60565b8114610d8657600080fd5b50565b600081359050610d9881610d72565b92915050565b60008115159050919050565b610db381610d9e565b8114610dbe57600080fd5b50565b600081359050610dd081610daa565b92915050565b60008060408385031215610ded57610dec610d3b565b5b6000610dfb85828601610d89565b9250506020610e0c85828601610dc1565b9150509250929050565b6000819050919050565b610e2981610e16565b82525050565b6000602082019050610e446000830184610e20565b92915050565b610e5381610e16565b8114610e5e57600080fd5b50565b600081359050610e7081610e4a565b92915050565b60008060408385031215610e8d57610e8c610d3b565b5b6000610e9b85828601610d89565b9250506020610eac85828601610e61565b9150509250929050565b600060208284031215610ecc57610ecb610d3b565b5b6000610eda84828501610e61565b91505092915050565b610eec81610d60565b82525050565b6000602082019050610f076000830184610ee3565b92915050565b610f1681610d9e565b82525050565b6000602082019050610f316000830184610f0d565b92915050565b600060208284031215610f4d57610f4c610d3b565b5b6000610f5b84828501610d89565b91505092915050565b600082825260208201905092915050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b6000610fab602083610f64565b9150610fb682610f75565b602082019050919050565b60006020820190508181036000830152610fda81610f9e565b9050919050565b7f4f776e66743a20544f4b454e204e4f5420454e41424c45440000000000000000600082015250565b6000611017601883610f64565b915061102282610fe1565b602082019050919050565b600060208201905081810360008301526110468161100a565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b600061108782610e16565b915061109283610e16565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff038211156110c7576110c661104d565b5b828201905092915050565b60006040820190506110e76000830185610ee3565b6110f46020830184610e20565b9392505050565b60006060820190506111106000830186610ee3565b61111d6020830185610ee3565b61112a6040830184610e20565b949350505050565b7f536166654d6174683a207375627472616374696f6e206f766572666c6f770000600082015250565b6000611168601e83610f64565b915061117382611132565b602082019050919050565b600060208201905081810360008301526111978161115b565b9050919050565b60006111a982610e16565b91506111b483610e16565b9250828210156111c7576111c661104d565b5b828203905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b600061120c82610e16565b915061121783610e16565b925082611227576112266111d2565b5b828204905092915050565b60008151905061124181610daa565b92915050565b60006020828403121561125d5761125c610d3b565b5b600061126b84828501611232565b91505092915050565b7f5361666545524332303a204552433230206f7065726174696f6e20646964206e60008201527f6f74207375636365656400000000000000000000000000000000000000000000602082015250565b60006112d0602a83610f64565b91506112db82611274565b604082019050919050565b600060208201905081810360008301526112ff816112c3565b9050919050565b600061131182610e16565b915061131c83610e16565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff04831182151516156113555761135461104d565b5b828202905092915050565b7f536166654d6174683a206d756c7469706c69636174696f6e206f766572666c6f60008201527f7700000000000000000000000000000000000000000000000000000000000000602082015250565b60006113bc602183610f64565b91506113c782611360565b604082019050919050565b600060208201905081810360008301526113eb816113af565b9050919050565b7f536166654d6174683a206164646974696f6e206f766572666c6f770000000000600082015250565b6000611428601b83610f64565b9150611433826113f2565b602082019050919050565b600060208201905081810360008301526114578161141b565b9050919050565b7f536166654d6174683a206469766973696f6e206279207a65726f000000000000600082015250565b6000611494601a83610f64565b915061149f8261145e565b602082019050919050565b600060208201905081810360008301526114c381611487565b9050919050565b7f416464726573733a20696e73756666696369656e742062616c616e636520666f60008201527f722063616c6c0000000000000000000000000000000000000000000000000000602082015250565b6000611526602683610f64565b9150611531826114ca565b604082019050919050565b6000602082019050818103600083015261155581611519565b9050919050565b7f416464726573733a2063616c6c20746f206e6f6e2d636f6e7472616374000000600082015250565b6000611592601d83610f64565b915061159d8261155c565b602082019050919050565b600060208201905081810360008301526115c181611585565b9050919050565b600081519050919050565b600081905092915050565b60005b838110156115fc5780820151818401526020810190506115e1565b8381111561160b576000848401525b50505050565b600061161c826115c8565b61162681856115d3565b93506116368185602086016115de565b80840191505092915050565b600061164e8284611611565b915081905092915050565b600081519050919050565b6000601f19601f8301169050919050565b600061168082611659565b61168a8185610f64565b935061169a8185602086016115de565b6116a381611664565b840191505092915050565b600060208201905081810360008301526116c88184611675565b90509291505056fea26469706673582212207022a45eb039d16fcf77ee52803c59f249c02874268798fc25c2e3f3e5db847b64736f6c63430008090033";

export class Ownft__factory extends ContractFactory {
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
    interest_rate: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<Ownft> {
    return super.deploy(interest_rate, overrides || {}) as Promise<Ownft>;
  }
  getDeployTransaction(
    interest_rate: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(interest_rate, overrides || {});
  }
  attach(address: string): Ownft {
    return super.attach(address) as Ownft;
  }
  connect(signer: Signer): Ownft__factory {
    return super.connect(signer) as Ownft__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): OwnftInterface {
    return new utils.Interface(_abi) as OwnftInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Ownft {
    return new Contract(address, _abi, signerOrProvider) as Ownft;
  }
}

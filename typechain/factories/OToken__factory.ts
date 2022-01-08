/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { OToken, OTokenInterface } from "../OToken";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_underlyingAsset",
        type: "address",
      },
      {
        internalType: "string",
        name: "_name",
        type: "string",
      },
      {
        internalType: "string",
        name: "_symbol",
        type: "string",
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
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
    ],
    name: "allowance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "subtractedValue",
        type: "uint256",
      },
    ],
    name: "decreaseAllowance",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "addedValue",
        type: "uint256",
      },
    ],
    name: "increaseAllowance",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "mintOnDeposit",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "recipient",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "transfer",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sender",
        type: "address",
      },
      {
        internalType: "address",
        name: "recipient",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "underlyingAssetAddress",
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

const _bytecode =
  "0x60806040523480156200001157600080fd5b50604051620019b7380380620019b7833981810160405281019062000037919062000328565b818181600390805190602001906200005192919062000076565b5080600490805190602001906200006a92919062000076565b50505050505062000427565b8280546200008490620003f1565b90600052602060002090601f016020900481019282620000a85760008555620000f4565b82601f10620000c357805160ff1916838001178555620000f4565b82800160010185558215620000f4579182015b82811115620000f3578251825591602001919060010190620000d6565b5b50905062000103919062000107565b5090565b5b808211156200012257600081600090555060010162000108565b5090565b6000604051905090565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600062000167826200013a565b9050919050565b62000179816200015a565b81146200018557600080fd5b50565b60008151905062000199816200016e565b92915050565b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b620001f482620001a9565b810181811067ffffffffffffffff82111715620002165762000215620001ba565b5b80604052505050565b60006200022b62000126565b9050620002398282620001e9565b919050565b600067ffffffffffffffff8211156200025c576200025b620001ba565b5b6200026782620001a9565b9050602081019050919050565b60005b838110156200029457808201518184015260208101905062000277565b83811115620002a4576000848401525b50505050565b6000620002c1620002bb846200023e565b6200021f565b905082815260208101848484011115620002e057620002df620001a4565b5b620002ed84828562000274565b509392505050565b600082601f8301126200030d576200030c6200019f565b5b81516200031f848260208601620002aa565b91505092915050565b60008060006060848603121562000344576200034362000130565b5b6000620003548682870162000188565b935050602084015167ffffffffffffffff81111562000378576200037762000135565b5b6200038686828701620002f5565b925050604084015167ffffffffffffffff811115620003aa57620003a962000135565b5b620003b886828701620002f5565b9150509250925092565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b600060028204905060018216806200040a57607f821691505b60208210811415620004215762000420620003c2565b5b50919050565b61158080620004376000396000f3fe608060405234801561001057600080fd5b50600436106100cf5760003560e01c806370a082311161008c57806395d89b411161006657806395d89b4114610228578063a457c2d714610246578063a9059cbb14610276578063dd62ed3e146102a6576100cf565b806370a08231146101be57806389d1a0fc146101ee57806394362e8b1461020c576100cf565b806306fdde03146100d4578063095ea7b3146100f257806318160ddd1461012257806323b872dd14610140578063313ce56714610170578063395093511461018e575b600080fd5b6100dc6102d6565b6040516100e99190610d58565b60405180910390f35b61010c60048036038101906101079190610e13565b610368565b6040516101199190610e6e565b60405180910390f35b61012a610386565b6040516101379190610e98565b60405180910390f35b61015a60048036038101906101559190610eb3565b610390565b6040516101679190610e6e565b60405180910390f35b610178610488565b6040516101859190610f22565b60405180910390f35b6101a860048036038101906101a39190610e13565b610491565b6040516101b59190610e6e565b60405180910390f35b6101d860048036038101906101d39190610f3d565b61053d565b6040516101e59190610e98565b60405180910390f35b6101f6610585565b6040516102039190610f79565b60405180910390f35b61022660048036038101906102219190610e13565b6105ab565b005b61023061063f565b60405161023d9190610d58565b60405180910390f35b610260600480360381019061025b9190610e13565b6106d1565b60405161026d9190610e6e565b60405180910390f35b610290600480360381019061028b9190610e13565b6107bc565b60405161029d9190610e6e565b60405180910390f35b6102c060048036038101906102bb9190610f94565b6107da565b6040516102cd9190610e98565b60405180910390f35b6060600380546102e590611003565b80601f016020809104026020016040519081016040528092919081815260200182805461031190611003565b801561035e5780601f106103335761010080835404028352916020019161035e565b820191906000526020600020905b81548152906001019060200180831161034157829003601f168201915b5050505050905090565b600061037c610375610861565b8484610869565b6001905092915050565b6000600254905090565b600061039d848484610a34565b6000600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006103e8610861565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905082811015610468576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161045f906110a7565b60405180910390fd5b61047c85610474610861565b858403610869565b60019150509392505050565b60006012905090565b600061053361049e610861565b8484600160006104ac610861565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205461052e91906110f6565b610869565b6001905092915050565b60008060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050919050565b600560009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600660009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461063b576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610632906111be565b60405180910390fd5b5050565b60606004805461064e90611003565b80601f016020809104026020016040519081016040528092919081815260200182805461067a90611003565b80156106c75780601f1061069c576101008083540402835291602001916106c7565b820191906000526020600020905b8154815290600101906020018083116106aa57829003601f168201915b5050505050905090565b600080600160006106e0610861565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205490508281101561079d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161079490611250565b60405180910390fd5b6107b16107a8610861565b85858403610869565b600191505092915050565b60006107d06107c9610861565b8484610a34565b6001905092915050565b6000600160008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905092915050565b600033905090565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614156108d9576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016108d0906112e2565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415610949576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161094090611374565b60405180910390fd5b80600160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92583604051610a279190610e98565b60405180910390a3505050565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415610aa4576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610a9b90611406565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415610b14576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b0b90611498565b60405180910390fd5b610b1f838383610cb5565b60008060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905081811015610ba5576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b9c9061152a565b60405180910390fd5b8181036000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550816000808573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610c3891906110f6565b925050819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef84604051610c9c9190610e98565b60405180910390a3610caf848484610cba565b50505050565b505050565b505050565b600081519050919050565b600082825260208201905092915050565b60005b83811015610cf9578082015181840152602081019050610cde565b83811115610d08576000848401525b50505050565b6000601f19601f8301169050919050565b6000610d2a82610cbf565b610d348185610cca565b9350610d44818560208601610cdb565b610d4d81610d0e565b840191505092915050565b60006020820190508181036000830152610d728184610d1f565b905092915050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610daa82610d7f565b9050919050565b610dba81610d9f565b8114610dc557600080fd5b50565b600081359050610dd781610db1565b92915050565b6000819050919050565b610df081610ddd565b8114610dfb57600080fd5b50565b600081359050610e0d81610de7565b92915050565b60008060408385031215610e2a57610e29610d7a565b5b6000610e3885828601610dc8565b9250506020610e4985828601610dfe565b9150509250929050565b60008115159050919050565b610e6881610e53565b82525050565b6000602082019050610e836000830184610e5f565b92915050565b610e9281610ddd565b82525050565b6000602082019050610ead6000830184610e89565b92915050565b600080600060608486031215610ecc57610ecb610d7a565b5b6000610eda86828701610dc8565b9350506020610eeb86828701610dc8565b9250506040610efc86828701610dfe565b9150509250925092565b600060ff82169050919050565b610f1c81610f06565b82525050565b6000602082019050610f376000830184610f13565b92915050565b600060208284031215610f5357610f52610d7a565b5b6000610f6184828501610dc8565b91505092915050565b610f7381610d9f565b82525050565b6000602082019050610f8e6000830184610f6a565b92915050565b60008060408385031215610fab57610faa610d7a565b5b6000610fb985828601610dc8565b9250506020610fca85828601610dc8565b9150509250929050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b6000600282049050600182168061101b57607f821691505b6020821081141561102f5761102e610fd4565b5b50919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206160008201527f6c6c6f77616e6365000000000000000000000000000000000000000000000000602082015250565b6000611091602883610cca565b915061109c82611035565b604082019050919050565b600060208201905081810360008301526110c081611084565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b600061110182610ddd565b915061110c83610ddd565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115611141576111406110c7565b5b828201905092915050565b7f5468652063616c6c6572206f6620746869732066756e6374696f6e206d75737460008201527f206265204f776e66740000000000000000000000000000000000000000000000602082015250565b60006111a8602983610cca565b91506111b38261114c565b604082019050919050565b600060208201905081810360008301526111d78161119b565b9050919050565b7f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f7760008201527f207a65726f000000000000000000000000000000000000000000000000000000602082015250565b600061123a602583610cca565b9150611245826111de565b604082019050919050565b600060208201905081810360008301526112698161122d565b9050919050565b7f45524332303a20617070726f76652066726f6d20746865207a65726f2061646460008201527f7265737300000000000000000000000000000000000000000000000000000000602082015250565b60006112cc602483610cca565b91506112d782611270565b604082019050919050565b600060208201905081810360008301526112fb816112bf565b9050919050565b7f45524332303a20617070726f766520746f20746865207a65726f20616464726560008201527f7373000000000000000000000000000000000000000000000000000000000000602082015250565b600061135e602283610cca565b915061136982611302565b604082019050919050565b6000602082019050818103600083015261138d81611351565b9050919050565b7f45524332303a207472616e736665722066726f6d20746865207a65726f20616460008201527f6472657373000000000000000000000000000000000000000000000000000000602082015250565b60006113f0602583610cca565b91506113fb82611394565b604082019050919050565b6000602082019050818103600083015261141f816113e3565b9050919050565b7f45524332303a207472616e7366657220746f20746865207a65726f206164647260008201527f6573730000000000000000000000000000000000000000000000000000000000602082015250565b6000611482602383610cca565b915061148d82611426565b604082019050919050565b600060208201905081810360008301526114b181611475565b9050919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206260008201527f616c616e63650000000000000000000000000000000000000000000000000000602082015250565b6000611514602683610cca565b915061151f826114b8565b604082019050919050565b6000602082019050818103600083015261154381611507565b905091905056fea2646970667358221220bdcc23c8b5d3a75b4fb4aa1600d6a113197d0f50a798d5d989ce1ec16639867b64736f6c63430008090033";

export class OToken__factory extends ContractFactory {
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
    _underlyingAsset: string,
    _name: string,
    _symbol: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<OToken> {
    return super.deploy(
      _underlyingAsset,
      _name,
      _symbol,
      overrides || {}
    ) as Promise<OToken>;
  }
  getDeployTransaction(
    _underlyingAsset: string,
    _name: string,
    _symbol: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _underlyingAsset,
      _name,
      _symbol,
      overrides || {}
    );
  }
  attach(address: string): OToken {
    return super.attach(address) as OToken;
  }
  connect(signer: Signer): OToken__factory {
    return super.connect(signer) as OToken__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): OTokenInterface {
    return new utils.Interface(_abi) as OTokenInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): OToken {
    return new Contract(address, _abi, signerOrProvider) as OToken;
  }
}

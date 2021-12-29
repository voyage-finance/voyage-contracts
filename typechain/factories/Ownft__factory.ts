/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Ownft, OwnftInterface } from "../Ownft";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "_token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_user",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_timestamp",
        type: "uint256",
      },
    ],
    name: "Deposit",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_interest_rate",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_operator",
        type: "address",
      },
    ],
    name: "InterestRateSet",
    type: "event",
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
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "_token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "_enable",
        type: "bool",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_operator",
        type: "address",
      },
    ],
    name: "WhilteListToken",
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
        name: "interest_rate",
        type: "uint256",
      },
    ],
    name: "setInvestorInterestRate",
    outputs: [],
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
  "0x608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a36001600281905550611858806100e36000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c80638f32d59b1161005b5780638f32d59b146100ed578063be8a468e1461010b578063e30c397814610127578063f2fde38b1461014557610088565b80633c7660351461008d57806347e7ef24146100a95780634e71e0c8146100c55780638da5cb5b146100cf575b600080fd5b6100a760048036038101906100a29190610f95565b610161565b005b6100c360048036038101906100be919061100b565b61023e565b005b6100cd61063e565b005b6100d76107da565b6040516100e4919061105a565b60405180910390f35b6100f56107fe565b6040516101029190611084565b60405180910390f35b6101256004803603810190610120919061100b565b610855565b005b61012f61091f565b60405161013c919061105a565b60405180910390f35b61015f600480360381019061015a919061109f565b610945565b005b6101696107fe565b6101a8576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161019f90611129565b60405180910390fd5b80600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055507ffa9f5283a216c74ca3bfdab3a8bfc5e42175867abde98826e581a949f2a262e282823360405161023293929190611149565b60405180910390a15050565b600280541415610283576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161027a906111cc565b60405180910390fd5b6002808190555060011515600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff1615151461031d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161031490611238565b60405180910390fd5b6000600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541161039f576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610396906112ca565b60405180910390fd5b6000600460003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020905060008160010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205411156105295760006104fa8260010160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054600560008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020548460020160008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020546109d0565b905061052733828673ffffffffffffffffffffffffffffffffffffffff16610a439092919063ffffffff16565b505b6105563330848673ffffffffffffffffffffffffffffffffffffffff16610ac9909392919063ffffffff16565b818160010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546105a79190611319565b92505081905550428160020160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055507fdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d783338442604051610629949392919061137e565b60405180910390a15060016002819055505050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461069857600080fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff166000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614905090565b61085d6107fe565b61089c576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161089390611129565b60405180910390fd5b80600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055507fda7938be27ecf634ad6716420601330f816fb3224d345ef21f7aa6714a6f9195338233604051610913939291906113c3565b60405180910390a15050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b61094d6107fe565b61098c576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161098390611129565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b6000806109e68342610b5290919063ffffffff16565b90506000610a116109fa6301e13380610b68565b610a0384610b68565b610b8890919063ffffffff16565b9050610a3886610a2a8388610be690919063ffffffff16565b610c4b90919063ffffffff16565b925050509392505050565b610ac48363a9059cbb60e01b8484604051602401610a629291906113fa565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050610c61565b505050565b610b4c846323b872dd60e01b858585604051602401610aea93929190611423565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050610c61565b50505050565b60008183610b60919061145a565b905092915050565b6000610b81633b9aca0083610c4b90919063ffffffff16565b9050919050565b600080600283610b9891906114bd565b9050610bdd83610bcf610bc06b033b2e3c9fd0803ce800000088610c4b90919063ffffffff16565b84610d2890919063ffffffff16565b610d3e90919063ffffffff16565b91505092915050565b6000610c436b033b2e3c9fd0803ce8000000610c35610c0e8587610c4b90919063ffffffff16565b60026b033b2e3c9fd0803ce8000000610c2791906114bd565b610d2890919063ffffffff16565b610d3e90919063ffffffff16565b905092915050565b60008183610c5991906114ee565b905092915050565b6000610cc3826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c65648152508573ffffffffffffffffffffffffffffffffffffffff16610d549092919063ffffffff16565b9050600081511115610d235780806020019051810190610ce3919061155d565b610d22576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610d19906115fc565b60405180910390fd5b5b505050565b60008183610d369190611319565b905092915050565b60008183610d4c91906114bd565b905092915050565b6060610d638484600085610d6c565b90509392505050565b606082471015610db1576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610da89061168e565b60405180910390fd5b610dba85610e80565b610df9576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610df0906116fa565b60405180910390fd5b6000808673ffffffffffffffffffffffffffffffffffffffff168587604051610e229190611794565b60006040518083038185875af1925050503d8060008114610e5f576040519150601f19603f3d011682016040523d82523d6000602084013e610e64565b606091505b5091509150610e74828286610e93565b92505050949350505050565b600080823b905060008111915050919050565b60608315610ea357829050610ef3565b600083511115610eb65782518084602001fd5b816040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610eea9190611800565b60405180910390fd5b9392505050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610f2a82610eff565b9050919050565b610f3a81610f1f565b8114610f4557600080fd5b50565b600081359050610f5781610f31565b92915050565b60008115159050919050565b610f7281610f5d565b8114610f7d57600080fd5b50565b600081359050610f8f81610f69565b92915050565b60008060408385031215610fac57610fab610efa565b5b6000610fba85828601610f48565b9250506020610fcb85828601610f80565b9150509250929050565b6000819050919050565b610fe881610fd5565b8114610ff357600080fd5b50565b60008135905061100581610fdf565b92915050565b6000806040838503121561102257611021610efa565b5b600061103085828601610f48565b925050602061104185828601610ff6565b9150509250929050565b61105481610f1f565b82525050565b600060208201905061106f600083018461104b565b92915050565b61107e81610f5d565b82525050565b60006020820190506110996000830184611075565b92915050565b6000602082840312156110b5576110b4610efa565b5b60006110c384828501610f48565b91505092915050565b600082825260208201905092915050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b60006111136020836110cc565b915061111e826110dd565b602082019050919050565b6000602082019050818103600083015261114281611106565b9050919050565b600060608201905061115e600083018661104b565b61116b6020830185611075565b611178604083018461104b565b949350505050565b7f5265656e7472616e637947756172643a207265656e7472616e742063616c6c00600082015250565b60006111b6601f836110cc565b91506111c182611180565b602082019050919050565b600060208201905081810360008301526111e5816111a9565b9050919050565b7f4f776e66743a20544f4b454e204e4f5420454e41424c45440000000000000000600082015250565b60006112226018836110cc565b915061122d826111ec565b602082019050919050565b6000602082019050818103600083015261125181611215565b9050919050565b7f4f776e66743a20544f4b454e20494e5445524553542052415445204e4f54205360008201527f4554000000000000000000000000000000000000000000000000000000000000602082015250565b60006112b46022836110cc565b91506112bf82611258565b604082019050919050565b600060208201905081810360008301526112e3816112a7565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b600061132482610fd5565b915061132f83610fd5565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115611364576113636112ea565b5b828201905092915050565b61137881610fd5565b82525050565b6000608082019050611393600083018761104b565b6113a0602083018661104b565b6113ad604083018561136f565b6113ba606083018461136f565b95945050505050565b60006060820190506113d8600083018661104b565b6113e5602083018561136f565b6113f2604083018461104b565b949350505050565b600060408201905061140f600083018561104b565b61141c602083018461136f565b9392505050565b6000606082019050611438600083018661104b565b611445602083018561104b565b611452604083018461136f565b949350505050565b600061146582610fd5565b915061147083610fd5565b925082821015611483576114826112ea565b5b828203905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b60006114c882610fd5565b91506114d383610fd5565b9250826114e3576114e261148e565b5b828204905092915050565b60006114f982610fd5565b915061150483610fd5565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff048311821515161561153d5761153c6112ea565b5b828202905092915050565b60008151905061155781610f69565b92915050565b60006020828403121561157357611572610efa565b5b600061158184828501611548565b91505092915050565b7f5361666545524332303a204552433230206f7065726174696f6e20646964206e60008201527f6f74207375636365656400000000000000000000000000000000000000000000602082015250565b60006115e6602a836110cc565b91506115f18261158a565b604082019050919050565b60006020820190508181036000830152611615816115d9565b9050919050565b7f416464726573733a20696e73756666696369656e742062616c616e636520666f60008201527f722063616c6c0000000000000000000000000000000000000000000000000000602082015250565b60006116786026836110cc565b91506116838261161c565b604082019050919050565b600060208201905081810360008301526116a78161166b565b9050919050565b7f416464726573733a2063616c6c20746f206e6f6e2d636f6e7472616374000000600082015250565b60006116e4601d836110cc565b91506116ef826116ae565b602082019050919050565b60006020820190508181036000830152611713816116d7565b9050919050565b600081519050919050565b600081905092915050565b60005b8381101561174e578082015181840152602081019050611733565b8381111561175d576000848401525b50505050565b600061176e8261171a565b6117788185611725565b9350611788818560208601611730565b80840191505092915050565b60006117a08284611763565b915081905092915050565b600081519050919050565b6000601f19601f8301169050919050565b60006117d2826117ab565b6117dc81856110cc565b93506117ec818560208601611730565b6117f5816117b6565b840191505092915050565b6000602082019050818103600083015261181a81846117c7565b90509291505056fea26469706673582212203a02b41000f8157bd27134e4e95506150cc2dfd7c5c76ece5a7a3e07682e45a464736f6c63430008090033";

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
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<Ownft> {
    return super.deploy(overrides || {}) as Promise<Ownft>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
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
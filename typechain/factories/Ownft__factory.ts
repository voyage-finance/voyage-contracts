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
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "_nft",
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
    name: "WhiteListNFT",
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
        name: "nft",
        type: "address",
      },
      {
        internalType: "bool",
        name: "enable",
        type: "bool",
      },
    ],
    name: "setNFTWhiteList",
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
  "0x608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160028190555061195c806100e36000396000f3fe608060405234801561001057600080fd5b50600436106100935760003560e01c80638da5cb5b116100665780638da5cb5b146100f65780638f32d59b14610114578063be8a468e14610132578063e30c39781461014e578063f2fde38b1461016c57610093565b806315682930146100985780633c766035146100b457806347e7ef24146100d05780634e71e0c8146100ec575b600080fd5b6100b260048036038101906100ad9190611099565b610188565b005b6100ce60048036038101906100c99190611099565b610265565b005b6100ea60048036038101906100e5919061110f565b610342565b005b6100f4610742565b005b6100fe6108de565b60405161010b919061115e565b60405180910390f35b61011c610902565b6040516101299190611188565b60405180910390f35b61014c6004803603810190610147919061110f565b610959565b005b610156610a23565b604051610163919061115e565b60405180910390f35b610186600480360381019061018191906111a3565b610a49565b005b610190610902565b6101cf576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016101c69061122d565b60405180910390fd5b80600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055507f0cb9047eafd5e3b01e45893a9e591f30fb843bf9c89a84d15ed78e030ff35dcf8282336040516102599392919061124d565b60405180910390a15050565b61026d610902565b6102ac576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016102a39061122d565b60405180910390fd5b80600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055507ffa9f5283a216c74ca3bfdab3a8bfc5e42175867abde98826e581a949f2a262e28282336040516103369392919061124d565b60405180910390a15050565b600280541415610387576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161037e906112d0565b60405180910390fd5b6002808190555060011515600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16151514610421576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016104189061133c565b60405180910390fd5b6000600660008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054116104a3576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161049a906113ce565b60405180910390fd5b6000600460003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020905060008160010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054111561062d5760006105fe8260010160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054600660008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020548460020160008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054610ad4565b905061062b33828673ffffffffffffffffffffffffffffffffffffffff16610b479092919063ffffffff16565b505b61065a3330848673ffffffffffffffffffffffffffffffffffffffff16610bcd909392919063ffffffff16565b818160010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546106ab919061141d565b92505081905550428160020160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055507fdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d78333844260405161072d9493929190611482565b60405180910390a15060016002819055505050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461079c57600080fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff166000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614905090565b610961610902565b6109a0576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016109979061122d565b60405180910390fd5b80600660008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055507fda7938be27ecf634ad6716420601330f816fb3224d345ef21f7aa6714a6f9195338233604051610a17939291906114c7565b60405180910390a15050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b610a51610902565b610a90576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610a879061122d565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b600080610aea8342610c5690919063ffffffff16565b90506000610b15610afe6301e13380610c6c565b610b0784610c6c565b610c8c90919063ffffffff16565b9050610b3c86610b2e8388610cea90919063ffffffff16565b610d4f90919063ffffffff16565b925050509392505050565b610bc88363a9059cbb60e01b8484604051602401610b669291906114fe565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050610d65565b505050565b610c50846323b872dd60e01b858585604051602401610bee93929190611527565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050610d65565b50505050565b60008183610c64919061155e565b905092915050565b6000610c85633b9aca0083610d4f90919063ffffffff16565b9050919050565b600080600283610c9c91906115c1565b9050610ce183610cd3610cc46b033b2e3c9fd0803ce800000088610d4f90919063ffffffff16565b84610e2c90919063ffffffff16565b610e4290919063ffffffff16565b91505092915050565b6000610d476b033b2e3c9fd0803ce8000000610d39610d128587610d4f90919063ffffffff16565b60026b033b2e3c9fd0803ce8000000610d2b91906115c1565b610e2c90919063ffffffff16565b610e4290919063ffffffff16565b905092915050565b60008183610d5d91906115f2565b905092915050565b6000610dc7826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c65648152508573ffffffffffffffffffffffffffffffffffffffff16610e589092919063ffffffff16565b9050600081511115610e275780806020019051810190610de79190611661565b610e26576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610e1d90611700565b60405180910390fd5b5b505050565b60008183610e3a919061141d565b905092915050565b60008183610e5091906115c1565b905092915050565b6060610e678484600085610e70565b90509392505050565b606082471015610eb5576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610eac90611792565b60405180910390fd5b610ebe85610f84565b610efd576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610ef4906117fe565b60405180910390fd5b6000808673ffffffffffffffffffffffffffffffffffffffff168587604051610f269190611898565b60006040518083038185875af1925050503d8060008114610f63576040519150601f19603f3d011682016040523d82523d6000602084013e610f68565b606091505b5091509150610f78828286610f97565b92505050949350505050565b600080823b905060008111915050919050565b60608315610fa757829050610ff7565b600083511115610fba5782518084602001fd5b816040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610fee9190611904565b60405180910390fd5b9392505050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061102e82611003565b9050919050565b61103e81611023565b811461104957600080fd5b50565b60008135905061105b81611035565b92915050565b60008115159050919050565b61107681611061565b811461108157600080fd5b50565b6000813590506110938161106d565b92915050565b600080604083850312156110b0576110af610ffe565b5b60006110be8582860161104c565b92505060206110cf85828601611084565b9150509250929050565b6000819050919050565b6110ec816110d9565b81146110f757600080fd5b50565b600081359050611109816110e3565b92915050565b6000806040838503121561112657611125610ffe565b5b60006111348582860161104c565b9250506020611145858286016110fa565b9150509250929050565b61115881611023565b82525050565b6000602082019050611173600083018461114f565b92915050565b61118281611061565b82525050565b600060208201905061119d6000830184611179565b92915050565b6000602082840312156111b9576111b8610ffe565b5b60006111c78482850161104c565b91505092915050565b600082825260208201905092915050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b60006112176020836111d0565b9150611222826111e1565b602082019050919050565b600060208201905081810360008301526112468161120a565b9050919050565b6000606082019050611262600083018661114f565b61126f6020830185611179565b61127c604083018461114f565b949350505050565b7f5265656e7472616e637947756172643a207265656e7472616e742063616c6c00600082015250565b60006112ba601f836111d0565b91506112c582611284565b602082019050919050565b600060208201905081810360008301526112e9816112ad565b9050919050565b7f4f776e66743a20544f4b454e204e4f5420454e41424c45440000000000000000600082015250565b60006113266018836111d0565b9150611331826112f0565b602082019050919050565b6000602082019050818103600083015261135581611319565b9050919050565b7f4f776e66743a20544f4b454e20494e5445524553542052415445204e4f54205360008201527f4554000000000000000000000000000000000000000000000000000000000000602082015250565b60006113b86022836111d0565b91506113c38261135c565b604082019050919050565b600060208201905081810360008301526113e7816113ab565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000611428826110d9565b9150611433836110d9565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115611468576114676113ee565b5b828201905092915050565b61147c816110d9565b82525050565b6000608082019050611497600083018761114f565b6114a4602083018661114f565b6114b16040830185611473565b6114be6060830184611473565b95945050505050565b60006060820190506114dc600083018661114f565b6114e96020830185611473565b6114f6604083018461114f565b949350505050565b6000604082019050611513600083018561114f565b6115206020830184611473565b9392505050565b600060608201905061153c600083018661114f565b611549602083018561114f565b6115566040830184611473565b949350505050565b6000611569826110d9565b9150611574836110d9565b925082821015611587576115866113ee565b5b828203905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b60006115cc826110d9565b91506115d7836110d9565b9250826115e7576115e6611592565b5b828204905092915050565b60006115fd826110d9565b9150611608836110d9565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0483118215151615611641576116406113ee565b5b828202905092915050565b60008151905061165b8161106d565b92915050565b60006020828403121561167757611676610ffe565b5b60006116858482850161164c565b91505092915050565b7f5361666545524332303a204552433230206f7065726174696f6e20646964206e60008201527f6f74207375636365656400000000000000000000000000000000000000000000602082015250565b60006116ea602a836111d0565b91506116f58261168e565b604082019050919050565b60006020820190508181036000830152611719816116dd565b9050919050565b7f416464726573733a20696e73756666696369656e742062616c616e636520666f60008201527f722063616c6c0000000000000000000000000000000000000000000000000000602082015250565b600061177c6026836111d0565b915061178782611720565b604082019050919050565b600060208201905081810360008301526117ab8161176f565b9050919050565b7f416464726573733a2063616c6c20746f206e6f6e2d636f6e7472616374000000600082015250565b60006117e8601d836111d0565b91506117f3826117b2565b602082019050919050565b60006020820190508181036000830152611817816117db565b9050919050565b600081519050919050565b600081905092915050565b60005b83811015611852578082015181840152602081019050611837565b83811115611861576000848401525b50505050565b60006118728261181e565b61187c8185611829565b935061188c818560208601611834565b80840191505092915050565b60006118a48284611867565b915081905092915050565b600081519050919050565b6000601f19601f8301169050919050565b60006118d6826118af565b6118e081856111d0565b93506118f0818560208601611834565b6118f9816118ba565b840191505092915050565b6000602082019050818103600083015261191e81846118cb565b90509291505056fea26469706673582212206560ff17c822560154f9bdf31f6ed91911f9956058d2719c9f824523e4c9ac9f64736f6c63430008090033";

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

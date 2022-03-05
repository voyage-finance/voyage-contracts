/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Escrow, EscrowInterface } from "../Escrow";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "payee",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "Deposited",
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
        indexed: true,
        internalType: "address",
        name: "payee",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "Withdrawn",
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
        internalType: "address",
        name: "_user",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "deposit",
    outputs: [],
    stateMutability: "payable",
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
        internalType: "address",
        name: "_user",
        type: "address",
      },
    ],
    name: "getDepositAmount",
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
        name: "_reserve",
        type: "address",
      },
      {
        internalType: "address",
        name: "_user",
        type: "address",
      },
    ],
    name: "getDepositRecords",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "amount",
            type: "uint256",
          },
          {
            internalType: "uint40",
            name: "depositTime",
            type: "uint40",
          },
        ],
        internalType: "struct Escrow.Deposit[]",
        name: "",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
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
  {
    inputs: [
      {
        internalType: "address",
        name: "_reserve",
        type: "address",
      },
      {
        internalType: "address payable",
        name: "_user",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "withdraw",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a36001600281905550611ec1806100e36000396000f3fe6080604052600436106100865760003560e01c80639932f036116100595780639932f03614610114578063d9caed1214610151578063e30c39781461017a578063f2fde38b146101a5578063f45b1b3a146101ce57610086565b80634e71e0c81461008b5780638340f549146100a25780638da5cb5b146100be5780638f32d59b146100e9575b600080fd5b34801561009757600080fd5b506100a061020b565b005b6100bc60048036038101906100b79190611385565b6103a7565b005b3480156100ca57600080fd5b506100d3610718565b6040516100e091906113e7565b60405180910390f35b3480156100f557600080fd5b506100fe61073c565b60405161010b919061141d565b60405180910390f35b34801561012057600080fd5b5061013b60048036038101906101369190611438565b610793565b6040516101489190611585565b60405180910390f35b34801561015d57600080fd5b50610178600480360381019061017391906115e5565b6108a8565b005b34801561018657600080fd5b5061018f610cff565b60405161019c91906113e7565b60405180910390f35b3480156101b157600080fd5b506101cc60048036038101906101c79190611638565b610d25565b005b3480156101da57600080fd5b506101f560048036038101906101f09190611438565b610db0565b6040516102029190611674565b60405180910390f35b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461026557600080fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff166000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b6002805414156103ec576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016103e3906116ec565b60405180910390fd5b600280819055506103fb61073c565b61043a576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161043190611758565b60405180910390fd5b610442610e37565b73ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff16146104e957600034146104b7576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016104ae906117ea565b60405180910390fd5b6104e48230838673ffffffffffffffffffffffffffffffffffffffff16610e53909392919063ffffffff16565b61052c565b80341461052b576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105229061187c565b60405180910390fd5b5b80600360008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546105b891906118cb565b92505081905550600060405180604001604052808381526020014264ffffffffff168152509050600460008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190806001815401808255809150506001900390600052602060002090600202016000909190919091506000820151816000015560208201518160010160006101000a81548164ffffffffff021916908364ffffffffff16021790555050508273ffffffffffffffffffffffffffffffffffffffff167f8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a78584604051610702929190611921565b60405180910390a2506001600281905550505050565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614905090565b60606000600460008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020905080805480602002602001604051908101604052809291908181526020016000905b8282101561089b5783829060005260206000209060020201604051806040016040529081600082015481526020016001820160009054906101000a900464ffffffffff1664ffffffffff1664ffffffffff168152505081526020019060010190610836565b5050505091505092915050565b6108b061073c565b6108ef576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016108e690611758565b60405180910390fd5b6000600460008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020905060008080600090505b8380549050811015610aaf57600560009054906101000a900464ffffffffff1664ffffffffff168482815481106109b2576109b161194a565b5b906000526020600020906002020160010160009054906101000a900464ffffffffff16426109e09190611979565b64ffffffffff161115610a9c57838181548110610a00576109ff61194a565b5b90600052602060002090600202016000015483610a1d91906118cb565b9250838181548110610a3257610a3161194a565b5b906000526020600020906002020160010160009054906101000a900464ffffffffff169150838181548110610a6a57610a6961194a565b5b90600052602060002090600202016000808201600090556001820160006101000a81549064ffffffffff021916905550505b8080610aa7906119ad565b915050610978565b5083821015610af3576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610aea90611a68565b60405180910390fd5b83821115610c095760008483610b099190611a88565b9050600060405180604001604052808381526020018464ffffffffff168152509050600460008973ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190806001815401808255809150506001900390600052602060002090600202016000909190919091506000820151816000015560208201518160010160006101000a81548164ffffffffff021916908364ffffffffff160217905550505050505b83600360008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610c959190611a88565b92505081905550610ca7868686610edc565b8473ffffffffffffffffffffffffffffffffffffffff167fd1c19fbcd4551a5edfb66d43d2e337c04837afda3482b42bdf569a8fccdae5fb8786604051610cef929190611921565b60405180910390a2505050505050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b610d2d61073c565b610d6c576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610d6390611758565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b6000600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905092915050565b600073eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee905090565b610ed6846323b872dd60e01b858585604051602401610e7493929190611abc565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050610ff9565b50505050565b610ee4610e37565b73ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614610f4657610f4182828573ffffffffffffffffffffffffffffffffffffffff166110c09092919063ffffffff16565b610ff4565b60008273ffffffffffffffffffffffffffffffffffffffff1682604051610f6c90611b24565b60006040518083038185875af1925050503d8060008114610fa9576040519150601f19603f3d011682016040523d82523d6000602084013e610fae565b606091505b5050905080610ff2576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610fe990611b85565b60405180910390fd5b505b505050565b600061105b826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c65648152508573ffffffffffffffffffffffffffffffffffffffff166111469092919063ffffffff16565b90506000815111156110bb578080602001905181019061107b9190611bd1565b6110ba576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016110b190611c70565b60405180910390fd5b5b505050565b6111418363a9059cbb60e01b84846040516024016110df929190611921565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050610ff9565b505050565b6060611155848460008561115e565b90509392505050565b6060824710156111a3576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161119a90611d02565b60405180910390fd5b6111ac85611272565b6111eb576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016111e290611d6e565b60405180910390fd5b6000808673ffffffffffffffffffffffffffffffffffffffff1685876040516112149190611dfd565b60006040518083038185875af1925050503d8060008114611251576040519150601f19603f3d011682016040523d82523d6000602084013e611256565b606091505b5091509150611266828286611285565b92505050949350505050565b600080823b905060008111915050919050565b60608315611295578290506112e5565b6000835111156112a85782518084602001fd5b816040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016112dc9190611e69565b60405180910390fd5b9392505050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061131c826112f1565b9050919050565b61132c81611311565b811461133757600080fd5b50565b60008135905061134981611323565b92915050565b6000819050919050565b6113628161134f565b811461136d57600080fd5b50565b60008135905061137f81611359565b92915050565b60008060006060848603121561139e5761139d6112ec565b5b60006113ac8682870161133a565b93505060206113bd8682870161133a565b92505060406113ce86828701611370565b9150509250925092565b6113e181611311565b82525050565b60006020820190506113fc60008301846113d8565b92915050565b60008115159050919050565b61141781611402565b82525050565b6000602082019050611432600083018461140e565b92915050565b6000806040838503121561144f5761144e6112ec565b5b600061145d8582860161133a565b925050602061146e8582860161133a565b9150509250929050565b600081519050919050565b600082825260208201905092915050565b6000819050602082019050919050565b6114ad8161134f565b82525050565b600064ffffffffff82169050919050565b6114cd816114b3565b82525050565b6040820160008201516114e960008501826114a4565b5060208201516114fc60208501826114c4565b50505050565b600061150e83836114d3565b60408301905092915050565b6000602082019050919050565b600061153282611478565b61153c8185611483565b935061154783611494565b8060005b8381101561157857815161155f8882611502565b975061156a8361151a565b92505060018101905061154b565b5085935050505092915050565b6000602082019050818103600083015261159f8184611527565b905092915050565b60006115b2826112f1565b9050919050565b6115c2816115a7565b81146115cd57600080fd5b50565b6000813590506115df816115b9565b92915050565b6000806000606084860312156115fe576115fd6112ec565b5b600061160c8682870161133a565b935050602061161d868287016115d0565b925050604061162e86828701611370565b9150509250925092565b60006020828403121561164e5761164d6112ec565b5b600061165c8482850161133a565b91505092915050565b61166e8161134f565b82525050565b60006020820190506116896000830184611665565b92915050565b600082825260208201905092915050565b7f5265656e7472616e637947756172643a207265656e7472616e742063616c6c00600082015250565b60006116d6601f8361168f565b91506116e1826116a0565b602082019050919050565b60006020820190508181036000830152611705816116c9565b9050919050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b600061174260208361168f565b915061174d8261170c565b602082019050919050565b6000602082019050818103600083015261177181611735565b9050919050565b7f557365722069732073656e64696e672045544820616c6f6e672077697468207460008201527f6865204552433230207472616e736665722e0000000000000000000000000000602082015250565b60006117d460328361168f565b91506117df82611778565b604082019050919050565b60006020820190508181036000830152611803816117c7565b9050919050565b7f54686520616d6f756e7420616e64207468652076616c75652073656e7420746f60008201527f206465706f73697420646f206e6f74206d617463680000000000000000000000602082015250565b600061186660358361168f565b91506118718261180a565b604082019050919050565b6000602082019050818103600083015261189581611859565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60006118d68261134f565b91506118e18361134f565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff038211156119165761191561189c565b5b828201905092915050565b600060408201905061193660008301856113d8565b6119436020830184611665565b9392505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b6000611984826114b3565b915061198f836114b3565b9250828210156119a2576119a161189c565b5b828203905092915050565b60006119b88261134f565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8214156119eb576119ea61189c565b5b600182019050919050565b7f446f206e6f74206861766520656e6f75676820616d6f756e7420746f2077697460008201527f6864726177000000000000000000000000000000000000000000000000000000602082015250565b6000611a5260258361168f565b9150611a5d826119f6565b604082019050919050565b60006020820190508181036000830152611a8181611a45565b9050919050565b6000611a938261134f565b9150611a9e8361134f565b925082821015611ab157611ab061189c565b5b828203905092915050565b6000606082019050611ad160008301866113d8565b611ade60208301856113d8565b611aeb6040830184611665565b949350505050565b600081905092915050565b50565b6000611b0e600083611af3565b9150611b1982611afe565b600082019050919050565b6000611b2f82611b01565b9150819050919050565b7f5472616e73666572206f6620455448206661696c656400000000000000000000600082015250565b6000611b6f60168361168f565b9150611b7a82611b39565b602082019050919050565b60006020820190508181036000830152611b9e81611b62565b9050919050565b611bae81611402565b8114611bb957600080fd5b50565b600081519050611bcb81611ba5565b92915050565b600060208284031215611be757611be66112ec565b5b6000611bf584828501611bbc565b91505092915050565b7f5361666545524332303a204552433230206f7065726174696f6e20646964206e60008201527f6f74207375636365656400000000000000000000000000000000000000000000602082015250565b6000611c5a602a8361168f565b9150611c6582611bfe565b604082019050919050565b60006020820190508181036000830152611c8981611c4d565b9050919050565b7f416464726573733a20696e73756666696369656e742062616c616e636520666f60008201527f722063616c6c0000000000000000000000000000000000000000000000000000602082015250565b6000611cec60268361168f565b9150611cf782611c90565b604082019050919050565b60006020820190508181036000830152611d1b81611cdf565b9050919050565b7f416464726573733a2063616c6c20746f206e6f6e2d636f6e7472616374000000600082015250565b6000611d58601d8361168f565b9150611d6382611d22565b602082019050919050565b60006020820190508181036000830152611d8781611d4b565b9050919050565b600081519050919050565b60005b83811015611db7578082015181840152602081019050611d9c565b83811115611dc6576000848401525b50505050565b6000611dd782611d8e565b611de18185611af3565b9350611df1818560208601611d99565b80840191505092915050565b6000611e098284611dcc565b915081905092915050565b600081519050919050565b6000601f19601f8301169050919050565b6000611e3b82611e14565b611e45818561168f565b9350611e55818560208601611d99565b611e5e81611e1f565b840191505092915050565b60006020820190508181036000830152611e838184611e30565b90509291505056fea2646970667358221220d76b8175346ccc2339b88265b306275fe3d0f96d9cb25be4db7804d51e3f3fc664736f6c63430008090033";

export class Escrow__factory extends ContractFactory {
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
  ): Promise<Escrow> {
    return super.deploy(overrides || {}) as Promise<Escrow>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): Escrow {
    return super.attach(address) as Escrow;
  }
  connect(signer: Signer): Escrow__factory {
    return super.connect(signer) as Escrow__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): EscrowInterface {
    return new utils.Interface(_abi) as EscrowInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Escrow {
    return new Contract(address, _abi, signerOrProvider) as Escrow;
  }
}

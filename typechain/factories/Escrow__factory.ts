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
    name: "renounceOwnership",
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
  "0x608060405234801561001057600080fd5b5061002d61002261003960201b60201c565b61004160201b60201c565b60018081905550610105565b600033905090565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050816000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508173ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a35050565b611189806101146000396000f3fe60806040526004361061003f5760003560e01c8063715018a6146100445780638340f5491461005b5780638da5cb5b14610077578063f2fde38b146100a2575b600080fd5b34801561005057600080fd5b506100596100cb565b005b61007560048036038101906100709190610a42565b610153565b005b34801561008357600080fd5b5061008c6104aa565b6040516100999190610aa4565b60405180910390f35b3480156100ae57600080fd5b506100c960048036038101906100c49190610abf565b6104d3565b005b6100d36105cb565b73ffffffffffffffffffffffffffffffffffffffff166100f16104aa565b73ffffffffffffffffffffffffffffffffffffffff1614610147576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161013e90610b49565b60405180910390fd5b61015160006105d3565b565b60026001541415610199576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161019090610bb5565b60405180910390fd5b60026001819055506101a96105cb565b73ffffffffffffffffffffffffffffffffffffffff166101c76104aa565b73ffffffffffffffffffffffffffffffffffffffff161461021d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161021490610b49565b60405180910390fd5b610225610697565b73ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff16146102cc576000341461029a576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161029190610c47565b60405180910390fd5b6102c78230838673ffffffffffffffffffffffffffffffffffffffff166106b3909392919063ffffffff16565b61030f565b80341461030e576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161030590610cd9565b60405180910390fd5b5b80600260008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825461039b9190610d28565b92505081905550600060405180604001604052808381526020014264ffffffffff168152509050600360008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190806001815401808255809150506001900390600052602060002090600202016000909190919091506000820151816000015560208201518160010160006101000a81548164ffffffffff021916908364ffffffffff16021790555050505060018081905550505050565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b6104db6105cb565b73ffffffffffffffffffffffffffffffffffffffff166104f96104aa565b73ffffffffffffffffffffffffffffffffffffffff161461054f576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161054690610b49565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff1614156105bf576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105b690610df0565b60405180910390fd5b6105c8816105d3565b50565b600033905090565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050816000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508173ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a35050565b600073eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee905090565b610736846323b872dd60e01b8585856040516024016106d493929190610e1f565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff838183161783525050505061073c565b50505050565b600061079e826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c65648152508573ffffffffffffffffffffffffffffffffffffffff166108039092919063ffffffff16565b90506000815111156107fe57808060200190518101906107be9190610e8e565b6107fd576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016107f490610f2d565b60405180910390fd5b5b505050565b6060610812848460008561081b565b90509392505050565b606082471015610860576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161085790610fbf565b60405180910390fd5b6108698561092f565b6108a8576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161089f9061102b565b60405180910390fd5b6000808673ffffffffffffffffffffffffffffffffffffffff1685876040516108d191906110c5565b60006040518083038185875af1925050503d806000811461090e576040519150601f19603f3d011682016040523d82523d6000602084013e610913565b606091505b5091509150610923828286610942565b92505050949350505050565b600080823b905060008111915050919050565b60608315610952578290506109a2565b6000835111156109655782518084602001fd5b816040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016109999190611131565b60405180910390fd5b9392505050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006109d9826109ae565b9050919050565b6109e9816109ce565b81146109f457600080fd5b50565b600081359050610a06816109e0565b92915050565b6000819050919050565b610a1f81610a0c565b8114610a2a57600080fd5b50565b600081359050610a3c81610a16565b92915050565b600080600060608486031215610a5b57610a5a6109a9565b5b6000610a69868287016109f7565b9350506020610a7a868287016109f7565b9250506040610a8b86828701610a2d565b9150509250925092565b610a9e816109ce565b82525050565b6000602082019050610ab96000830184610a95565b92915050565b600060208284031215610ad557610ad46109a9565b5b6000610ae3848285016109f7565b91505092915050565b600082825260208201905092915050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b6000610b33602083610aec565b9150610b3e82610afd565b602082019050919050565b60006020820190508181036000830152610b6281610b26565b9050919050565b7f5265656e7472616e637947756172643a207265656e7472616e742063616c6c00600082015250565b6000610b9f601f83610aec565b9150610baa82610b69565b602082019050919050565b60006020820190508181036000830152610bce81610b92565b9050919050565b7f557365722069732073656e64696e672045544820616c6f6e672077697468207460008201527f6865204552433230207472616e736665722e0000000000000000000000000000602082015250565b6000610c31603283610aec565b9150610c3c82610bd5565b604082019050919050565b60006020820190508181036000830152610c6081610c24565b9050919050565b7f54686520616d6f756e7420616e64207468652076616c75652073656e7420746f60008201527f206465706f73697420646f206e6f74206d617463680000000000000000000000602082015250565b6000610cc3603583610aec565b9150610cce82610c67565b604082019050919050565b60006020820190508181036000830152610cf281610cb6565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000610d3382610a0c565b9150610d3e83610a0c565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115610d7357610d72610cf9565b5b828201905092915050565b7f4f776e61626c653a206e6577206f776e657220697320746865207a65726f206160008201527f6464726573730000000000000000000000000000000000000000000000000000602082015250565b6000610dda602683610aec565b9150610de582610d7e565b604082019050919050565b60006020820190508181036000830152610e0981610dcd565b9050919050565b610e1981610a0c565b82525050565b6000606082019050610e346000830186610a95565b610e416020830185610a95565b610e4e6040830184610e10565b949350505050565b60008115159050919050565b610e6b81610e56565b8114610e7657600080fd5b50565b600081519050610e8881610e62565b92915050565b600060208284031215610ea457610ea36109a9565b5b6000610eb284828501610e79565b91505092915050565b7f5361666545524332303a204552433230206f7065726174696f6e20646964206e60008201527f6f74207375636365656400000000000000000000000000000000000000000000602082015250565b6000610f17602a83610aec565b9150610f2282610ebb565b604082019050919050565b60006020820190508181036000830152610f4681610f0a565b9050919050565b7f416464726573733a20696e73756666696369656e742062616c616e636520666f60008201527f722063616c6c0000000000000000000000000000000000000000000000000000602082015250565b6000610fa9602683610aec565b9150610fb482610f4d565b604082019050919050565b60006020820190508181036000830152610fd881610f9c565b9050919050565b7f416464726573733a2063616c6c20746f206e6f6e2d636f6e7472616374000000600082015250565b6000611015601d83610aec565b915061102082610fdf565b602082019050919050565b6000602082019050818103600083015261104481611008565b9050919050565b600081519050919050565b600081905092915050565b60005b8381101561107f578082015181840152602081019050611064565b8381111561108e576000848401525b50505050565b600061109f8261104b565b6110a98185611056565b93506110b9818560208601611061565b80840191505092915050565b60006110d18284611094565b915081905092915050565b600081519050919050565b6000601f19601f8301169050919050565b6000611103826110dc565b61110d8185610aec565b935061111d818560208601611061565b611126816110e7565b840191505092915050565b6000602082019050818103600083015261114b81846110f8565b90509291505056fea26469706673582212208b2f2ea9e32d93ecce347cd850e932cd4719e676c0bc9ec5862ccc691ca33e7b64736f6c63430008090033";

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
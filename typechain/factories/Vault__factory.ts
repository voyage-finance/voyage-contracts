/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Vault, VaultInterface } from "../Vault";

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
        indexed: true,
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "bytes32",
        name: "previousAdminRole",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "bytes32",
        name: "newAdminRole",
        type: "bytes32",
      },
    ],
    name: "RoleAdminChanged",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address",
      },
    ],
    name: "RoleGranted",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address",
      },
    ],
    name: "RoleRevoked",
    type: "event",
  },
  {
    inputs: [],
    name: "BORROWER",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "DEFAULT_ADMIN_ROLE",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "addressResolver",
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
    name: "factory",
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
        name: "role",
        type: "bytes32",
      },
    ],
    name: "getRoleAdmin",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "grantRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "hasRole",
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
    inputs: [
      {
        internalType: "address",
        name: "_addressResolver",
        type: "address",
      },
      {
        internalType: "address",
        name: "borrower",
        type: "address",
      },
    ],
    name: "initialize",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    name: "players",
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
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "renounceRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "revokeRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
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
];

const _bytecode =
  "0x608060405234801561001057600080fd5b5033600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550611290806100616000396000f3fe608060405234801561001057600080fd5b50600436106100b45760003560e01c8063485cc95511610071578063485cc9551461018d57806391d14854146101a9578063a217fddf146101d9578063c45a0155146101f7578063d547741f14610215578063f71d96cb14610231576100b4565b806301ffc9a7146100b957806305a2ee2a146100e9578063065d570f14610107578063248a9ca3146101255780632f2ff15d1461015557806336568abe14610171575b600080fd5b6100d360048036038101906100ce9190610b65565b610261565b6040516100e09190610bad565b60405180910390f35b6100f16102db565b6040516100fe9190610c09565b60405180910390f35b61010f610301565b60405161011c9190610c3d565b60405180910390f35b61013f600480360381019061013a9190610c84565b610325565b60405161014c9190610c3d565b60405180910390f35b61016f600480360381019061016a9190610cdd565b610344565b005b61018b60048036038101906101869190610cdd565b61036d565b005b6101a760048036038101906101a29190610d1d565b6103f0565b005b6101c360048036038101906101be9190610cdd565b6104ef565b6040516101d09190610bad565b60405180910390f35b6101e1610559565b6040516101ee9190610c3d565b60405180910390f35b6101ff610560565b60405161020c9190610c09565b60405180910390f35b61022f600480360381019061022a9190610cdd565b610586565b005b61024b60048036038101906102469190610d93565b6105af565b6040516102589190610c09565b60405180910390f35b60007f7965db0b000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff191614806102d457506102d3826105ee565b5b9050919050565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b7fbf87e2252b7172d9c61058578b6bef80f9573784ab4e27044251da25a76ed28e81565b6000806000838152602001908152602001600020600101549050919050565b61034d82610325565b61035e81610359610658565b610660565b61036883836106fd565b505050565b610375610658565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16146103e2576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016103d990610e43565b60405180910390fd5b6103ec82826107dd565b5050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610480576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161047790610eaf565b60405180910390fd5b81600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506104eb7fbf87e2252b7172d9c61058578b6bef80f9573784ab4e27044251da25a76ed28e826108be565b5050565b600080600084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16905092915050565b6000801b81565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b61058f82610325565b6105a08161059b610658565b610660565b6105aa83836107dd565b505050565b600381815481106105bf57600080fd5b906000526020600020016000915054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60007f01ffc9a7000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916149050919050565b600033905090565b61066a82826104ef565b6106f95761068f8173ffffffffffffffffffffffffffffffffffffffff1660146108cc565b61069d8360001c60206108cc565b6040516020016106ae929190610fe1565b6040516020818303038152906040526040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016106f09190611065565b60405180910390fd5b5050565b61070782826104ef565b6107d957600160008084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff02191690831515021790555061077e610658565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45b5050565b6107e782826104ef565b156108ba57600080600084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff02191690831515021790555061085f610658565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16837ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b60405160405180910390a45b5050565b6108c882826106fd565b5050565b6060600060028360026108df91906110b6565b6108e99190611110565b67ffffffffffffffff81111561090257610901611166565b5b6040519080825280601f01601f1916602001820160405280156109345781602001600182028036833780820191505090505b5090507f30000000000000000000000000000000000000000000000000000000000000008160008151811061096c5761096b611195565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a9053507f7800000000000000000000000000000000000000000000000000000000000000816001815181106109d0576109cf611195565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a90535060006001846002610a1091906110b6565b610a1a9190611110565b90505b6001811115610aba577f3031323334353637383961626364656600000000000000000000000000000000600f861660108110610a5c57610a5b611195565b5b1a60f81b828281518110610a7357610a72611195565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a905350600485901c945080610ab3906111c4565b9050610a1d565b5060008414610afe576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610af59061123a565b60405180910390fd5b8091505092915050565b600080fd5b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b610b4281610b0d565b8114610b4d57600080fd5b50565b600081359050610b5f81610b39565b92915050565b600060208284031215610b7b57610b7a610b08565b5b6000610b8984828501610b50565b91505092915050565b60008115159050919050565b610ba781610b92565b82525050565b6000602082019050610bc26000830184610b9e565b92915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610bf382610bc8565b9050919050565b610c0381610be8565b82525050565b6000602082019050610c1e6000830184610bfa565b92915050565b6000819050919050565b610c3781610c24565b82525050565b6000602082019050610c526000830184610c2e565b92915050565b610c6181610c24565b8114610c6c57600080fd5b50565b600081359050610c7e81610c58565b92915050565b600060208284031215610c9a57610c99610b08565b5b6000610ca884828501610c6f565b91505092915050565b610cba81610be8565b8114610cc557600080fd5b50565b600081359050610cd781610cb1565b92915050565b60008060408385031215610cf457610cf3610b08565b5b6000610d0285828601610c6f565b9250506020610d1385828601610cc8565b9150509250929050565b60008060408385031215610d3457610d33610b08565b5b6000610d4285828601610cc8565b9250506020610d5385828601610cc8565b9150509250929050565b6000819050919050565b610d7081610d5d565b8114610d7b57600080fd5b50565b600081359050610d8d81610d67565b92915050565b600060208284031215610da957610da8610b08565b5b6000610db784828501610d7e565b91505092915050565b600082825260208201905092915050565b7f416363657373436f6e74726f6c3a2063616e206f6e6c792072656e6f756e636560008201527f20726f6c657320666f722073656c660000000000000000000000000000000000602082015250565b6000610e2d602f83610dc0565b9150610e3882610dd1565b604082019050919050565b60006020820190508181036000830152610e5c81610e20565b9050919050565b7f566f7961676572205661756c743a20464f5242494444454e0000000000000000600082015250565b6000610e99601883610dc0565b9150610ea482610e63565b602082019050919050565b60006020820190508181036000830152610ec881610e8c565b9050919050565b600081905092915050565b7f416363657373436f6e74726f6c3a206163636f756e7420000000000000000000600082015250565b6000610f10601783610ecf565b9150610f1b82610eda565b601782019050919050565b600081519050919050565b60005b83811015610f4f578082015181840152602081019050610f34565b83811115610f5e576000848401525b50505050565b6000610f6f82610f26565b610f798185610ecf565b9350610f89818560208601610f31565b80840191505092915050565b7f206973206d697373696e6720726f6c6520000000000000000000000000000000600082015250565b6000610fcb601183610ecf565b9150610fd682610f95565b601182019050919050565b6000610fec82610f03565b9150610ff88285610f64565b915061100382610fbe565b915061100f8284610f64565b91508190509392505050565b6000601f19601f8301169050919050565b600061103782610f26565b6110418185610dc0565b9350611051818560208601610f31565b61105a8161101b565b840191505092915050565b6000602082019050818103600083015261107f818461102c565b905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60006110c182610d5d565b91506110cc83610d5d565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff048311821515161561110557611104611087565b5b828202905092915050565b600061111b82610d5d565b915061112683610d5d565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0382111561115b5761115a611087565b5b828201905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b60006111cf82610d5d565b915060008214156111e3576111e2611087565b5b600182039050919050565b7f537472696e67733a20686578206c656e67746820696e73756666696369656e74600082015250565b6000611224602083610dc0565b915061122f826111ee565b602082019050919050565b6000602082019050818103600083015261125381611217565b905091905056fea2646970667358221220a0449b3e5f3c38323b85c863d429a3b2cff1903d6a27ce5ea8adc83f99fac78864736f6c63430008090033";

export class Vault__factory extends ContractFactory {
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
  ): Promise<Vault> {
    return super.deploy(overrides || {}) as Promise<Vault>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): Vault {
    return super.attach(address) as Vault;
  }
  connect(signer: Signer): Vault__factory {
    return super.connect(signer) as Vault__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): VaultInterface {
    return new utils.Interface(_abi) as VaultInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Vault {
    return new Contract(address, _abi, signerOrProvider) as Vault;
  }
}

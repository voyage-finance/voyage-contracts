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
    name: "UserDeposit",
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
    inputs: [
      {
        internalType: "address",
        name: "nft",
        type: "address",
      },
    ],
    name: "borrow",
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
  "0x608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a36001600281905550612127806100e36000396000f3fe608060405234801561001057600080fd5b506004361061009e5760003560e01c80638da5cb5b116100665780638da5cb5b1461011d5780638f32d59b1461013b578063be8a468e14610159578063e30c397814610175578063f2fde38b146101935761009e565b806315682930146100a35780633c766035146100bf5780633f0ead02146100db57806347e7ef24146100f75780634e71e0c814610113575b600080fd5b6100bd60048036038101906100b89190611466565b6101af565b005b6100d960048036038101906100d49190611466565b61028c565b005b6100f560048036038101906100f091906114a6565b610369565b005b610111600480360381019061010c9190611509565b610629565b005b61011b610a29565b005b610125610bc5565b6040516101329190611558565b60405180910390f35b610143610be9565b6040516101509190611582565b60405180910390f35b610173600480360381019061016e9190611509565b610c40565b005b61017d610d0a565b60405161018a9190611558565b60405180910390f35b6101ad60048036038101906101a891906114a6565b610d30565b005b6101b7610be9565b6101f6576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016101ed906115fa565b60405180910390fd5b80600460008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055507f0cb9047eafd5e3b01e45893a9e591f30fb843bf9c89a84d15ed78e030ff35dcf8282336040516102809392919061161a565b60405180910390a15050565b610294610be9565b6102d3576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016102ca906115fa565b60405180910390fd5b80600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055507ffa9f5283a216c74ca3bfdab3a8bfc5e42175867abde98826e581a949f2a262e282823360405161035d9392919061161a565b60405180910390a15050565b6002805414156103ae576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016103a59061169d565b60405180910390fd5b6002808190555060011515600460008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16151514610448576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161043f90611709565b60405180910390fd5b6000600660003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020905060008160020154116104d2576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016104c990611775565b60405180910390fd5b600080600860008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1690508183600201600082825461054b91906117c4565b92505081905550428360030181905550808360010160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060006105aa3330610dbb565b9050808460000160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555061061a81848473ffffffffffffffffffffffffffffffffffffffff16610e949092919063ffffffff16565b50505050600160028190555050565b60028054141561066e576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016106659061169d565b60405180910390fd5b6002808190555060011515600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16151514610708576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016106ff90611866565b60405180910390fd5b6000600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541161078a576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610781906118f8565b60405180910390fd5b6000600760003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020905060008160010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205411156109145760006108e58260010160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054600560008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020548460020160008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054610f1a565b905061091233828673ffffffffffffffffffffffffffffffffffffffff16610e949092919063ffffffff16565b505b6109413330848673ffffffffffffffffffffffffffffffffffffffff16610f8d909392919063ffffffff16565b818160010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825461099291906117c4565b92505081905550428160020160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055507f21d06a8a4f8be1ad09d9fcec8304a99826528ae79f66bcd05d6bcc0f955236ec83338442604051610a149493929190611927565b60405180910390a15060016002819055505050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610a8357600080fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff166000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614905090565b610c48610be9565b610c87576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610c7e906115fa565b60405180910390fd5b80600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055507fda7938be27ecf634ad6716420601330f816fb3224d345ef21f7aa6714a6f9195338233604051610cfe9392919061196c565b60405180910390a15050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b610d38610be9565b610d77576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610d6e906115fa565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b60008060405180602001610dce906113be565b6020820181038252601f19601f820116604052509050600084604051602001610df791906119eb565b6040516020818303038152906040528051906020012090506000818351602085016000f590508073ffffffffffffffffffffffffffffffffffffffff1663c4d66de8876040518263ffffffff1660e01b8152600401610e569190611558565b600060405180830381600087803b158015610e7057600080fd5b505af1158015610e84573d6000803e3d6000fd5b5050505080935050505092915050565b610f158363a9059cbb60e01b8484604051602401610eb3929190611a06565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050611016565b505050565b600080610f3083426110dd90919063ffffffff16565b90506000610f5b610f446301e133806110f3565b610f4d846110f3565b61111390919063ffffffff16565b9050610f8286610f74838861117190919063ffffffff16565b6111d690919063ffffffff16565b925050509392505050565b611010846323b872dd60e01b858585604051602401610fae93929190611a2f565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050611016565b50505050565b6000611078826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c65648152508573ffffffffffffffffffffffffffffffffffffffff166111ec9092919063ffffffff16565b90506000815111156110d857808060200190518101906110989190611a7b565b6110d7576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016110ce90611b1a565b60405180910390fd5b5b505050565b600081836110eb9190611b3a565b905092915050565b600061110c633b9aca00836111d690919063ffffffff16565b9050919050565b6000806002836111239190611b9d565b90506111688361115a61114b6b033b2e3c9fd0803ce8000000886111d690919063ffffffff16565b8461120490919063ffffffff16565b61121a90919063ffffffff16565b91505092915050565b60006111ce6b033b2e3c9fd0803ce80000006111c061119985876111d690919063ffffffff16565b60026b033b2e3c9fd0803ce80000006111b29190611b9d565b61120490919063ffffffff16565b61121a90919063ffffffff16565b905092915050565b600081836111e49190611bce565b905092915050565b60606111fb8484600085611230565b90509392505050565b6000818361121291906117c4565b905092915050565b600081836112289190611b9d565b905092915050565b606082471015611275576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161126c90611c9a565b60405180910390fd5b61127e85611344565b6112bd576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016112b490611d06565b60405180910390fd5b6000808673ffffffffffffffffffffffffffffffffffffffff1685876040516112e69190611da0565b60006040518083038185875af1925050503d8060008114611323576040519150601f19603f3d011682016040523d82523d6000602084013e611328565b606091505b5091509150611338828286611357565b92505050949350505050565b600080823b905060008111915050919050565b60608315611367578290506113b7565b60008351111561137a5782518084602001fd5b816040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016113ae9190611e0c565b60405180910390fd5b9392505050565b6102c380611e2f83390190565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006113fb826113d0565b9050919050565b61140b816113f0565b811461141657600080fd5b50565b60008135905061142881611402565b92915050565b60008115159050919050565b6114438161142e565b811461144e57600080fd5b50565b6000813590506114608161143a565b92915050565b6000806040838503121561147d5761147c6113cb565b5b600061148b85828601611419565b925050602061149c85828601611451565b9150509250929050565b6000602082840312156114bc576114bb6113cb565b5b60006114ca84828501611419565b91505092915050565b6000819050919050565b6114e6816114d3565b81146114f157600080fd5b50565b600081359050611503816114dd565b92915050565b600080604083850312156115205761151f6113cb565b5b600061152e85828601611419565b925050602061153f858286016114f4565b9150509250929050565b611552816113f0565b82525050565b600060208201905061156d6000830184611549565b92915050565b61157c8161142e565b82525050565b60006020820190506115976000830184611573565b92915050565b600082825260208201905092915050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b60006115e460208361159d565b91506115ef826115ae565b602082019050919050565b60006020820190508181036000830152611613816115d7565b9050919050565b600060608201905061162f6000830186611549565b61163c6020830185611573565b6116496040830184611549565b949350505050565b7f5265656e7472616e637947756172643a207265656e7472616e742063616c6c00600082015250565b6000611687601f8361159d565b915061169282611651565b602082019050919050565b600060208201905081810360008301526116b68161167a565b9050919050565b7f4f776e66743a204e4654204e4f5420454e41424c454400000000000000000000600082015250565b60006116f360168361159d565b91506116fe826116bd565b602082019050919050565b60006020820190508181036000830152611722816116e6565b9050919050565b7f4f776e66743a20494e56414c494420424f52524f574552000000000000000000600082015250565b600061175f60178361159d565b915061176a82611729565b602082019050919050565b6000602082019050818103600083015261178e81611752565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60006117cf826114d3565b91506117da836114d3565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0382111561180f5761180e611795565b5b828201905092915050565b7f4f776e66743a20544f4b454e204e4f5420454e41424c45440000000000000000600082015250565b600061185060188361159d565b915061185b8261181a565b602082019050919050565b6000602082019050818103600083015261187f81611843565b9050919050565b7f4f776e66743a20544f4b454e20494e5445524553542052415445204e4f54205360008201527f4554000000000000000000000000000000000000000000000000000000000000602082015250565b60006118e260228361159d565b91506118ed82611886565b604082019050919050565b60006020820190508181036000830152611911816118d5565b9050919050565b611921816114d3565b82525050565b600060808201905061193c6000830187611549565b6119496020830186611549565b6119566040830185611918565b6119636060830184611918565b95945050505050565b60006060820190506119816000830186611549565b61198e6020830185611918565b61199b6040830184611549565b949350505050565b60008160601b9050919050565b60006119bb826119a3565b9050919050565b60006119cd826119b0565b9050919050565b6119e56119e0826113f0565b6119c2565b82525050565b60006119f782846119d4565b60148201915081905092915050565b6000604082019050611a1b6000830185611549565b611a286020830184611918565b9392505050565b6000606082019050611a446000830186611549565b611a516020830185611549565b611a5e6040830184611918565b949350505050565b600081519050611a758161143a565b92915050565b600060208284031215611a9157611a906113cb565b5b6000611a9f84828501611a66565b91505092915050565b7f5361666545524332303a204552433230206f7065726174696f6e20646964206e60008201527f6f74207375636365656400000000000000000000000000000000000000000000602082015250565b6000611b04602a8361159d565b9150611b0f82611aa8565b604082019050919050565b60006020820190508181036000830152611b3381611af7565b9050919050565b6000611b45826114d3565b9150611b50836114d3565b925082821015611b6357611b62611795565b5b828203905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b6000611ba8826114d3565b9150611bb3836114d3565b925082611bc357611bc2611b6e565b5b828204905092915050565b6000611bd9826114d3565b9150611be4836114d3565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0483118215151615611c1d57611c1c611795565b5b828202905092915050565b7f416464726573733a20696e73756666696369656e742062616c616e636520666f60008201527f722063616c6c0000000000000000000000000000000000000000000000000000602082015250565b6000611c8460268361159d565b9150611c8f82611c28565b604082019050919050565b60006020820190508181036000830152611cb381611c77565b9050919050565b7f416464726573733a2063616c6c20746f206e6f6e2d636f6e7472616374000000600082015250565b6000611cf0601d8361159d565b9150611cfb82611cba565b602082019050919050565b60006020820190508181036000830152611d1f81611ce3565b9050919050565b600081519050919050565b600081905092915050565b60005b83811015611d5a578082015181840152602081019050611d3f565b83811115611d69576000848401525b50505050565b6000611d7a82611d26565b611d848185611d31565b9350611d94818560208601611d3c565b80840191505092915050565b6000611dac8284611d6f565b915081905092915050565b600081519050919050565b6000601f19601f8301169050919050565b6000611dde82611db7565b611de8818561159d565b9350611df8818560208601611d3c565b611e0181611dc2565b840191505092915050565b60006020820190508181036000830152611e268184611dd3565b90509291505056fe608060405234801561001057600080fd5b506102a3806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063c4d66de814610030575b600080fd5b61004a600480360381019061004591906101c3565b61004c565b005b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146100dc576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016100d39061024d565b60405180910390fd5b806000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555033600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061019082610165565b9050919050565b6101a081610185565b81146101ab57600080fd5b50565b6000813590506101bd81610197565b92915050565b6000602082840312156101d9576101d8610160565b5b60006101e7848285016101ae565b91505092915050565b600082825260208201905092915050565b7f4465706f7369743a20464f5242494444454e0000000000000000000000000000600082015250565b60006102376012836101f0565b915061024282610201565b602082019050919050565b600060208201905081810360008301526102668161022a565b905091905056fea264697066735822122037043d3e9dfc4f14bc6044eeec6bb28181e61033c460abff97f3caeab58dbbae64736f6c63430008090033a2646970667358221220e1a88125159cc48d8f20dfd3eb711df6e21f8569a7a7221dbd2c0e47f1755e0264736f6c63430008090033";

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

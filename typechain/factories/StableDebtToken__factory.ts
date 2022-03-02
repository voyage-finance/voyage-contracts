/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type {
  StableDebtToken,
  StableDebtTokenInterface,
} from "../StableDebtToken";

const _abi = [
  {
    inputs: [
      {
        internalType: "string",
        name: "debtTokenName",
        type: "string",
      },
      {
        internalType: "string",
        name: "debtTokenSymbol",
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
        name: "user",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "currentBalance",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "balanceIncrease",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "avgStableRate",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "newTotalSupply",
        type: "uint256",
      },
    ],
    name: "Burn",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "underlyingAsset",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "pool",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint8",
        name: "aTokenDecimals",
        type: "uint8",
      },
      {
        indexed: false,
        internalType: "string",
        name: "aTokenName",
        type: "string",
      },
      {
        indexed: false,
        internalType: "string",
        name: "aTokenSymbol",
        type: "string",
      },
      {
        indexed: false,
        internalType: "bytes",
        name: "params",
        type: "bytes",
      },
    ],
    name: "Initialized",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "onBehalfOf",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "currentBalance",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "balanceIncrease",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "newRate",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "avgStableRate",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "newTotalSupply",
        type: "uint256",
      },
    ],
    name: "Mint",
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
    inputs: [],
    name: "DEBT_TOKEN_REVISION",
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
    inputs: [
      {
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "burn",
    outputs: [],
    stateMutability: "nonpayable",
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
    inputs: [],
    name: "getAverageStableRate",
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
        name: "user",
        type: "address",
      },
    ],
    name: "getUserLastUpdated",
    outputs: [
      {
        internalType: "uint40",
        name: "",
        type: "uint40",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "user",
        type: "address",
      },
    ],
    name: "getUserStableRate",
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
        internalType: "contract LiquidityManager",
        name: "lm",
        type: "address",
      },
      {
        internalType: "address",
        name: "underlyingAsset",
        type: "address",
      },
      {
        internalType: "uint8",
        name: "debtTokenDecimals",
        type: "uint8",
      },
      {
        internalType: "bytes",
        name: "params",
        type: "bytes",
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
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        internalType: "address",
        name: "onBehalfOf",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "rate",
        type: "uint256",
      },
    ],
    name: "mint",
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
];

const _bytecode =
  "0x60806040523480156200001157600080fd5b506040516200306a3803806200306a8339818101604052810190620000379190620002c2565b818181600390805190602001906200005192919062000075565b5080600490805190602001906200006a92919062000075565b5050505050620003ac565b828054620000839062000376565b90600052602060002090601f016020900481019282620000a75760008555620000f3565b82601f10620000c257805160ff1916838001178555620000f3565b82800160010185558215620000f3579182015b82811115620000f2578251825591602001919060010190620000d5565b5b50905062000102919062000106565b5090565b5b808211156200012157600081600090555060010162000107565b5090565b6000604051905090565b600080fd5b600080fd5b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6200018e8262000143565b810181811067ffffffffffffffff82111715620001b057620001af62000154565b5b80604052505050565b6000620001c562000125565b9050620001d3828262000183565b919050565b600067ffffffffffffffff821115620001f657620001f562000154565b5b620002018262000143565b9050602081019050919050565b60005b838110156200022e57808201518184015260208101905062000211565b838111156200023e576000848401525b50505050565b60006200025b6200025584620001d8565b620001b9565b9050828152602081018484840111156200027a57620002796200013e565b5b620002878482856200020e565b509392505050565b600082601f830112620002a757620002a662000139565b5b8151620002b984826020860162000244565b91505092915050565b60008060408385031215620002dc57620002db6200012f565b5b600083015167ffffffffffffffff811115620002fd57620002fc62000134565b5b6200030b858286016200028f565b925050602083015167ffffffffffffffff8111156200032f576200032e62000134565b5b6200033d858286016200028f565b9150509250929050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b600060028204905060018216806200038f57607f821691505b60208210811415620003a657620003a562000347565b5b50919050565b612cae80620003bc6000396000f3fe608060405234801561001057600080fd5b50600436106101165760003560e01c806395d89b41116100a2578063b3f1c93d11610071578063b3f1c93d1461031d578063b9a7b6221461034d578063c9729c371461036b578063dd62ed3e14610387578063e78c9b3b146103b757610116565b806395d89b41146102835780639dc29fac146102a1578063a457c2d7146102bd578063a9059cbb146102ed57610116565b8063313ce567116100e9578063313ce567146101b757806339509351146101d557806370a082311461020557806379ce6b8c1461023557806390f6fcf21461026557610116565b806306fdde031461011b578063095ea7b31461013957806318160ddd1461016957806323b872dd14610187575b600080fd5b6101236103e7565b6040516101309190612067565b60405180910390f35b610153600480360381019061014e9190612127565b610479565b6040516101609190612182565b60405180910390f35b610171610497565b60405161017e91906121ac565b60405180910390f35b6101a1600480360381019061019c91906121c7565b6104a9565b6040516101ae9190612182565b60405180910390f35b6101bf6105a1565b6040516101cc9190612236565b60405180910390f35b6101ef60048036038101906101ea9190612127565b6105aa565b6040516101fc9190612182565b60405180910390f35b61021f600480360381019061021a9190612251565b610656565b60405161022c91906121ac565b60405180910390f35b61024f600480360381019061024a9190612251565b610738565b60405161025c919061229e565b60405180910390f35b61026d610792565b60405161027a91906121ac565b60405180910390f35b61028b61079c565b6040516102989190612067565b60405180910390f35b6102bb60048036038101906102b69190612127565b61082e565b005b6102d760048036038101906102d29190612127565b610caa565b6040516102e49190612182565b60405180910390f35b61030760048036038101906103029190612127565b610d95565b6040516103149190612182565b60405180910390f35b610337600480360381019061033291906122b9565b610db3565b6040516103449190612182565b60405180910390f35b610355611227565b60405161036291906121ac565b60405180910390f35b610385600480360381019061038091906123ef565b61122c565b005b6103a1600480360381019061039c9190612477565b61134b565b6040516103ae91906121ac565b60405180910390f35b6103d160048036038101906103cc9190612251565b6113d2565b6040516103de91906121ac565b60405180910390f35b6060600380546103f6906124e6565b80601f0160208091040260200160405190810160405280929190818152602001828054610422906124e6565b801561046f5780601f106104445761010080835404028352916020019161046f565b820191906000526020600020905b81548152906001019060200180831161045257829003601f168201915b5050505050905090565b600061048d61048661141b565b8484611423565b6001905092915050565b60006104a46005546115ee565b905090565b60006104b684848461164c565b6000600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600061050161141b565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905082811015610581576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105789061258a565b60405180910390fd5b6105958561058d61141b565b858403611423565b60019150509392505050565b60006012905090565b600061064c6105b761141b565b8484600160006105c561141b565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205461064791906125d9565b611423565b6001905092915050565b600080610662836118cd565b90506000600760008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905060008214156106bc57600092505050610733565b600061071882600660008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900464ffffffffff16611915565b905061072d818461192a90919063ffffffff16565b93505050505b919050565b6000600660008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900464ffffffffff169050919050565b6000600554905090565b6060600480546107ab906124e6565b80601f01602080910402602001604051908101604052809291908181526020018280546107d7906124e6565b80156108245780601f106107f957610100808354040283529160200191610824565b820191906000526020600020905b81548152906001019060200180831161080757829003601f168201915b5050505050905090565b600960059054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146108be576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016108b5906126a1565b60405180910390fd5b6000806108ca8461198f565b925092505060006108d9610497565b90506000806000600760008973ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905086841161093e57600060058190555060006002819055506109ea565b61095187856119fe90919063ffffffff16565b60028190559150600061097761096686611a14565b60055461192a90919063ffffffff16565b905060006109966109878a611a14565b8461192a90919063ffffffff16565b90508181106109b25760006002819055600581905594506109e7565b6109df6109be85611a14565b6109d183856119fe90919063ffffffff16565b611a3490919063ffffffff16565b600581905594505b50505b85871415610a9d576000600760008a73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055506000600660008a73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548164ffffffffff021916908364ffffffffff160217905550610afe565b42600660008a73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548164ffffffffff021916908364ffffffffff1602179055505b42600960006101000a81548164ffffffffff021916908364ffffffffff16021790555086851115610bc0576000610b3e88876119fe90919063ffffffff16565b9050610b4b898287611a92565b8873ffffffffffffffffffffffffffffffffffffffff168973ffffffffffffffffffffffffffffffffffffffff167fc16f4e4ca34d790de4c656c72fd015c667d688f20be64eea360618545c4c530f838a8a878a8a604051610bb2969594939291906126c1565b60405180910390a350610c3a565b6000610bd586896119fe90919063ffffffff16565b9050610be2898287611b30565b8873ffffffffffffffffffffffffffffffffffffffff167f44bd20a79e993bdcc7cbedf54a3b4d19fb78490124b6b90d04fe3242eea579e88289898888604051610c30959493929190612722565b60405180910390a2505b600073ffffffffffffffffffffffffffffffffffffffff168873ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef89604051610c9891906121ac565b60405180910390a35050505050505050565b60008060016000610cb961141b565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905082811015610d76576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610d6d906127e7565b60405180910390fd5b610d8a610d8161141b565b85858403611423565b600191505092915050565b6000610da9610da261141b565b848461164c565b6001905092915050565b6000600960059054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610e45576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610e3c906126a1565b60405180910390fd5b610e4d611f9f565b8473ffffffffffffffffffffffffffffffffffffffff168673ffffffffffffffffffffffffffffffffffffffff1614610e8c57610e8b858786611c05565b5b600080610e988761198f565b9250925050610ea5610497565b836000018181525050600554836080018181525050610ed1868460000151611d5690919063ffffffff16565b6002819055836020018181525050610ee886611a14565b836040018181525050610f9f610f0f610f0a8885611d5690919063ffffffff16565b611a14565b610f91610f2988876040015161192a90919063ffffffff16565b610f83610f3587611a14565b600760008e73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205461192a90919063ffffffff16565b611d5690919063ffffffff16565b611a3490919063ffffffff16565b8360600181815250506fffffffffffffffffffffffffffffffff8016836060015111156040518060400160405280600281526020017f373900000000000000000000000000000000000000000000000000000000000081525090611039576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016110309190612067565b60405180910390fd5b508260600151600760008973ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190555042600660008973ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548164ffffffffff021916908364ffffffffff1602179055600960006101000a81548164ffffffffff021916908364ffffffffff16021790555061116c6111138460200151611a14565b61115e61112d86604001518961192a90919063ffffffff16565b61115061113d8860000151611a14565b886080015161192a90919063ffffffff16565b611d5690919063ffffffff16565b611a3490919063ffffffff16565b600581905583608001818152505061119b876111918389611d5690919063ffffffff16565b8560000151611a92565b8673ffffffffffffffffffffffffffffffffffffffff168873ffffffffffffffffffffffffffffffffffffffff167fc16f4e4ca34d790de4c656c72fd015c667d688f20be64eea360618545c4c530f888585886060015189608001518a6020015160405161120e969594939291906126c1565b60405180910390a3600082149350505050949350505050565b600181565b82600a60146101000a81548160ff021916908360ff16021790555084600960056101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555083600a60006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508473ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167f5d8ce3e947367e84e7fa4f4ba36ebe75e6b6c6b93c25673faa4df0202b59c138856113216103e7565b61132961079c565b878760405161133c959493929190612854565b60405180910390a35050505050565b6000600160008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905092915050565b6000600760008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050919050565b600033905090565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415611493576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161148a90612922565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415611503576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016114fa906129b4565b60405180910390fd5b80600160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925836040516115e191906121ac565b60405180910390a3505050565b6000806115f9611d6c565b9050600081141561160e576000915050611647565b600061162d84600960009054906101000a900464ffffffffff16611915565b9050611642818361192a90919063ffffffff16565b925050505b919050565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614156116bc576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016116b390612a46565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff16141561172c576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161172390612ad8565b60405180910390fd5b611737838383611d76565b60008060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050818110156117bd576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016117b490612b6a565b60405180910390fd5b8181036000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550816000808573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825461185091906125d9565b925050819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040516118b491906121ac565b60405180910390a36118c7848484611d7b565b50505050565b60008060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050919050565b6000611922838342611d80565b905092915050565b60006119876b033b2e3c9fd0803ce80000006119796119528587611f0a90919063ffffffff16565b60026b033b2e3c9fd0803ce800000061196b9190612bb9565b611d5690919063ffffffff16565b611f2090919063ffffffff16565b905092915050565b60008060008061199e856118cd565b905060008114156119ba576000806000935093509350506119f7565b60006119d7826119c988610656565b6119fe90919063ffffffff16565b9050816119ed8284611d5690919063ffffffff16565b8294509450945050505b9193909250565b60008183611a0c9190612bea565b905092915050565b6000611a2d633b9aca0083611f0a90919063ffffffff16565b9050919050565b600080600283611a449190612bb9565b9050611a8983611a7b611a6c6b033b2e3c9fd0803ce800000088611f0a90919063ffffffff16565b84611d5690919063ffffffff16565b611f2090919063ffffffff16565b91505092915050565b60008060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050611ae88382611d5690919063ffffffff16565b6000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190555050505050565b60008060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050611bbd836040518060400160405280601881526020017f5344545f4255524e5f455843454544535f42414c414e4345000000000000000081525083611f369092919063ffffffff16565b6000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190555050505050565b6000611ccd826040518060400160405280600281526020017f3539000000000000000000000000000000000000000000000000000000000000815250600860008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054611f369092919063ffffffff16565b905080600860008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190555050505050565b60008183611d6491906125d9565b905092915050565b6000600254905090565b505050565b505050565b600080611d9d8464ffffffffff16846119fe90919063ffffffff16565b90506000811415611db857611db0611f8b565b915050611f03565b6000600182611dc79190612bea565b9050600060028311611dda576000611de8565b600283611de79190612bea565b5b905060006301e1338088611dfc9190612bb9565b90506000611e13828361192a90919063ffffffff16565b90506000611e2a838361192a90919063ffffffff16565b905060006002611e5584611e47898b611f0a90919063ffffffff16565b611f0a90919063ffffffff16565b611e5f9190612bb9565b905060006006611e9c84611e8e89611e808c8e611f0a90919063ffffffff16565b611f0a90919063ffffffff16565b611f0a90919063ffffffff16565b611ea69190612bb9565b9050611ef881611eea84611edc611ec68d8b611f0a90919063ffffffff16565b611ece611f8b565b611d5690919063ffffffff16565b611d5690919063ffffffff16565b611d5690919063ffffffff16565b985050505050505050505b9392505050565b60008183611f189190612c1e565b905092915050565b60008183611f2e9190612bb9565b905092915050565b6000838311158290611f7e576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611f759190612067565b60405180910390fd5b5082840390509392505050565b60006b033b2e3c9fd0803ce8000000905090565b6040518060a0016040528060008152602001600081526020016000815260200160008152602001600081525090565b600081519050919050565b600082825260208201905092915050565b60005b83811015612008578082015181840152602081019050611fed565b83811115612017576000848401525b50505050565b6000601f19601f8301169050919050565b600061203982611fce565b6120438185611fd9565b9350612053818560208601611fea565b61205c8161201d565b840191505092915050565b60006020820190508181036000830152612081818461202e565b905092915050565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006120be82612093565b9050919050565b6120ce816120b3565b81146120d957600080fd5b50565b6000813590506120eb816120c5565b92915050565b6000819050919050565b612104816120f1565b811461210f57600080fd5b50565b600081359050612121816120fb565b92915050565b6000806040838503121561213e5761213d612089565b5b600061214c858286016120dc565b925050602061215d85828601612112565b9150509250929050565b60008115159050919050565b61217c81612167565b82525050565b60006020820190506121976000830184612173565b92915050565b6121a6816120f1565b82525050565b60006020820190506121c1600083018461219d565b92915050565b6000806000606084860312156121e0576121df612089565b5b60006121ee868287016120dc565b93505060206121ff868287016120dc565b925050604061221086828701612112565b9150509250925092565b600060ff82169050919050565b6122308161221a565b82525050565b600060208201905061224b6000830184612227565b92915050565b60006020828403121561226757612266612089565b5b6000612275848285016120dc565b91505092915050565b600064ffffffffff82169050919050565b6122988161227e565b82525050565b60006020820190506122b3600083018461228f565b92915050565b600080600080608085870312156122d3576122d2612089565b5b60006122e1878288016120dc565b94505060206122f2878288016120dc565b935050604061230387828801612112565b925050606061231487828801612112565b91505092959194509250565b600061232b826120b3565b9050919050565b61233b81612320565b811461234657600080fd5b50565b60008135905061235881612332565b92915050565b6123678161221a565b811461237257600080fd5b50565b6000813590506123848161235e565b92915050565b600080fd5b600080fd5b600080fd5b60008083601f8401126123af576123ae61238a565b5b8235905067ffffffffffffffff8111156123cc576123cb61238f565b5b6020830191508360018202830111156123e8576123e7612394565b5b9250929050565b60008060008060006080868803121561240b5761240a612089565b5b600061241988828901612349565b955050602061242a888289016120dc565b945050604061243b88828901612375565b935050606086013567ffffffffffffffff81111561245c5761245b61208e565b5b61246888828901612399565b92509250509295509295909350565b6000806040838503121561248e5761248d612089565b5b600061249c858286016120dc565b92505060206124ad858286016120dc565b9150509250929050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b600060028204905060018216806124fe57607f821691505b60208210811415612512576125116124b7565b5b50919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206160008201527f6c6c6f77616e6365000000000000000000000000000000000000000000000000602082015250565b6000612574602883611fd9565b915061257f82612518565b604082019050919050565b600060208201905081810360008301526125a381612567565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60006125e4826120f1565b91506125ef836120f1565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115612624576126236125aa565b5b828201905092915050565b7f5468652063616c6c6572206f6620746869732066756e6374696f6e206d75737460008201527f206265206c69717569646974794d616e61676572000000000000000000000000602082015250565b600061268b603483611fd9565b91506126968261262f565b604082019050919050565b600060208201905081810360008301526126ba8161267e565b9050919050565b600060c0820190506126d6600083018961219d565b6126e3602083018861219d565b6126f0604083018761219d565b6126fd606083018661219d565b61270a608083018561219d565b61271760a083018461219d565b979650505050505050565b600060a082019050612737600083018861219d565b612744602083018761219d565b612751604083018661219d565b61275e606083018561219d565b61276b608083018461219d565b9695505050505050565b7f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f7760008201527f207a65726f000000000000000000000000000000000000000000000000000000602082015250565b60006127d1602583611fd9565b91506127dc82612775565b604082019050919050565b60006020820190508181036000830152612800816127c4565b9050919050565b600082825260208201905092915050565b82818337600083830152505050565b60006128338385612807565b9350612840838584612818565b6128498361201d565b840190509392505050565b60006080820190506128696000830188612227565b818103602083015261287b818761202e565b9050818103604083015261288f818661202e565b905081810360608301526128a4818486612827565b90509695505050505050565b7f45524332303a20617070726f76652066726f6d20746865207a65726f2061646460008201527f7265737300000000000000000000000000000000000000000000000000000000602082015250565b600061290c602483611fd9565b9150612917826128b0565b604082019050919050565b6000602082019050818103600083015261293b816128ff565b9050919050565b7f45524332303a20617070726f766520746f20746865207a65726f20616464726560008201527f7373000000000000000000000000000000000000000000000000000000000000602082015250565b600061299e602283611fd9565b91506129a982612942565b604082019050919050565b600060208201905081810360008301526129cd81612991565b9050919050565b7f45524332303a207472616e736665722066726f6d20746865207a65726f20616460008201527f6472657373000000000000000000000000000000000000000000000000000000602082015250565b6000612a30602583611fd9565b9150612a3b826129d4565b604082019050919050565b60006020820190508181036000830152612a5f81612a23565b9050919050565b7f45524332303a207472616e7366657220746f20746865207a65726f206164647260008201527f6573730000000000000000000000000000000000000000000000000000000000602082015250565b6000612ac2602383611fd9565b9150612acd82612a66565b604082019050919050565b60006020820190508181036000830152612af181612ab5565b9050919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206260008201527f616c616e63650000000000000000000000000000000000000000000000000000602082015250565b6000612b54602683611fd9565b9150612b5f82612af8565b604082019050919050565b60006020820190508181036000830152612b8381612b47565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b6000612bc4826120f1565b9150612bcf836120f1565b925082612bdf57612bde612b8a565b5b828204905092915050565b6000612bf5826120f1565b9150612c00836120f1565b925082821015612c1357612c126125aa565b5b828203905092915050565b6000612c29826120f1565b9150612c34836120f1565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0483118215151615612c6d57612c6c6125aa565b5b82820290509291505056fea26469706673582212206b3d3378b49a831051b6e9eecfadee9072e1b7da95e3d3df347b0308cce4bc7764736f6c63430008090033";

export class StableDebtToken__factory extends ContractFactory {
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
    debtTokenName: string,
    debtTokenSymbol: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<StableDebtToken> {
    return super.deploy(
      debtTokenName,
      debtTokenSymbol,
      overrides || {}
    ) as Promise<StableDebtToken>;
  }
  getDeployTransaction(
    debtTokenName: string,
    debtTokenSymbol: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      debtTokenName,
      debtTokenSymbol,
      overrides || {}
    );
  }
  attach(address: string): StableDebtToken {
    return super.attach(address) as StableDebtToken;
  }
  connect(signer: Signer): StableDebtToken__factory {
    return super.connect(signer) as StableDebtToken__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): StableDebtTokenInterface {
    return new utils.Interface(_abi) as StableDebtTokenInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): StableDebtToken {
    return new Contract(address, _abi, signerOrProvider) as StableDebtToken;
  }
}

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
import type { VToken, VTokenInterface } from "../VToken";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_underlyingAsset",
        type: "address",
      },
      {
        internalType: "uint8",
        name: "_underlyingAssetDecimals",
        type: "uint8",
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
        name: "_from",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_fromBalanceIncrease",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_fromIndex",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "enum CoreLibrary.Tranche",
        name: "tranche",
        type: "uint8",
      },
    ],
    name: "MintOnDeposit",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "_from",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_fromBalanceIncrease",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_fromIndex",
        type: "uint256",
      },
    ],
    name: "Redeem",
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
        name: "_user",
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
        internalType: "enum CoreLibrary.Tranche",
        name: "_tranche",
        type: "uint8",
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
  "0x60806040523480156200001157600080fd5b506040516200263b3803806200263b833981810160405281019062000037919062000367565b818181600390805190602001906200005192919062000077565b5080600490805190602001906200006a92919062000077565b505050505050506200047c565b828054620000859062000446565b90600052602060002090601f016020900481019282620000a95760008555620000f5565b82601f10620000c457805160ff1916838001178555620000f5565b82800160010185558215620000f5579182015b82811115620000f4578251825591602001919060010190620000d7565b5b50905062000104919062000108565b5090565b5b808211156200012357600081600090555060010162000109565b5090565b6000604051905090565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600062000168826200013b565b9050919050565b6200017a816200015b565b81146200018657600080fd5b50565b6000815190506200019a816200016f565b92915050565b600060ff82169050919050565b620001b881620001a0565b8114620001c457600080fd5b50565b600081519050620001d881620001ad565b92915050565b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6200023382620001e8565b810181811067ffffffffffffffff82111715620002555762000254620001f9565b5b80604052505050565b60006200026a62000127565b905062000278828262000228565b919050565b600067ffffffffffffffff8211156200029b576200029a620001f9565b5b620002a682620001e8565b9050602081019050919050565b60005b83811015620002d3578082015181840152602081019050620002b6565b83811115620002e3576000848401525b50505050565b600062000300620002fa846200027d565b6200025e565b9050828152602081018484840111156200031f576200031e620001e3565b5b6200032c848285620002b3565b509392505050565b600082601f8301126200034c576200034b620001de565b5b81516200035e848260208601620002e9565b91505092915050565b6000806000806080858703121562000384576200038362000131565b5b6000620003948782880162000189565b9450506020620003a787828801620001c7565b935050604085015167ffffffffffffffff811115620003cb57620003ca62000136565b5b620003d98782880162000334565b925050606085015167ffffffffffffffff811115620003fd57620003fc62000136565b5b6200040b8782880162000334565b91505092959194509250565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b600060028204905060018216806200045f57607f821691505b6020821081141562000476576200047562000417565b5b50919050565b6121af806200048c6000396000f3fe608060405234801561001057600080fd5b50600436106100cf5760003560e01c806370a082311161008c578063a071334111610066578063a07133411461022a578063a457c2d714610246578063a9059cbb14610276578063dd62ed3e146102a6576100cf565b806370a08231146101be57806389d1a0fc146101ee57806395d89b411461020c576100cf565b806306fdde03146100d4578063095ea7b3146100f257806318160ddd1461012257806323b872dd14610140578063313ce56714610170578063395093511461018e575b600080fd5b6100dc6102d6565b6040516100e9919061168e565b60405180910390f35b61010c60048036038101906101079190611749565b610368565b60405161011991906117a4565b60405180910390f35b61012a610386565b60405161013791906117ce565b60405180910390f35b61015a600480360381019061015591906117e9565b610390565b60405161016791906117a4565b60405180910390f35b610178610488565b6040516101859190611858565b60405180910390f35b6101a860048036038101906101a39190611749565b610491565b6040516101b591906117a4565b60405180910390f35b6101d860048036038101906101d39190611873565b61053d565b6040516101e591906117ce565b60405180910390f35b6101f661059a565b60405161020391906118af565b60405180910390f35b6102146105c0565b604051610221919061168e565b60405180910390f35b610244600480360381019061023f91906118ef565b610652565b005b610260600480360381019061025b9190611749565b61075a565b60405161026d91906117a4565b60405180910390f35b610290600480360381019061028b9190611749565b610845565b60405161029d91906117a4565b60405180910390f35b6102c060048036038101906102bb9190611942565b610863565b6040516102cd91906117ce565b60405180910390f35b6060600380546102e5906119b1565b80601f0160208091040260200160405190810160405280929190818152602001828054610311906119b1565b801561035e5780601f106103335761010080835404028352916020019161035e565b820191906000526020600020905b81548152906001019060200180831161034157829003601f168201915b5050505050905090565b600061037c6103756108ea565b84846108f2565b6001905092915050565b6000600254905090565b600061039d848484610abd565b6000600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006103e86108ea565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905082811015610468576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161045f90611a55565b60405180910390fd5b61047c856104746108ea565b8584036108f2565b60019150509392505050565b60006012905090565b600061053361049e6108ea565b8484600160006104ac6108ea565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205461052e9190611aa4565b6108f2565b6001905092915050565b60008061054983610d3e565b9050600061055984600084610d86565b9050600061056985600185610d86565b905061059081610582848661104990919063ffffffff16565b61104990919063ffffffff16565b9350505050919050565b600760009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6060600480546105cf906119b1565b80601f01602080910402602001604051908101604052809291908181526020018280546105fb906119b1565b80156106485780601f1061061d57610100808354040283529160200191610648565b820191906000526020600020905b81548152906001019060200180831161062b57829003601f168201915b5050505050905090565b600860009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146106e2576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016106d990611b6c565b60405180910390fd5b6000806106ef858561105f565b9350935050506106ff858461131f565b8473ffffffffffffffffffffffffffffffffffffffff167ffb59c8bf0cbd3215b9dae301155d8cf8b67756432f3102f2ed1677b1fbeb70178484848860405161074b9493929190611c03565b60405180910390a25050505050565b600080600160006107696108ea565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905082811015610826576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161081d90611cba565b60405180910390fd5b61083a6108316108ea565b858584036108f2565b600191505092915050565b60006108596108526108ea565b8484610abd565b6001905092915050565b6000600160008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905092915050565b600033905090565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415610962576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161095990611d4c565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff1614156109d2576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016109c990611dde565b60405180910390fd5b80600160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92583604051610ab091906117ce565b60405180910390a3505050565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415610b2d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b2490611e70565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415610b9d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b9490611f02565b60405180910390fd5b610ba883838361147f565b60008060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905081811015610c2e576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610c2590611f94565b60405180910390fd5b8181036000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550816000808573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610cc19190611aa4565b925050819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef84604051610d2591906117ce565b60405180910390a3610d38848484611484565b50505050565b60008060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050919050565b6000806001811115610d9b57610d9a611b8c565b5b836001811115610dae57610dad611b8c565b5b1415610efd57610ef6610ef1600560008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054610ee3600860009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663776f6891600760009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16896040518363ffffffff1660e01b8152600401610e7c929190611fb4565b60206040518083038186803b158015610e9457600080fd5b505afa158015610ea8573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610ecc9190611ff2565b610ed587611489565b6114a990919063ffffffff16565b61150e90919063ffffffff16565b61156c565b9050611042565b61103f61103a600660008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205461102c600860009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663776f6891600760009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16896040518363ffffffff1660e01b8152600401610fc5929190611fb4565b60206040518083038186803b158015610fdd57600080fd5b505afa158015610ff1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906110159190611ff2565b61101e87611489565b6114a990919063ffffffff16565b61150e90919063ffffffff16565b61156c565b90505b9392505050565b600081836110579190611aa4565b905092915050565b600080600080600061107087610d3e565b9050600061108f826110818a61053d565b6115b390919063ffffffff16565b905061109b888261131f565b60008060018111156110b0576110af611b8c565b5b8860018111156110c3576110c2611b8c565b5b14156111e157600860009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663776f6891600760009054906101000a900473ffffffffffffffffffffffffffffffffffffffff168a6040518363ffffffff1660e01b8152600401611148929190611fb4565b60206040518083038186803b15801561116057600080fd5b505afa158015611174573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906111989190611ff2565b600560008b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905590506112f5565b600860009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663776f6891600760009054906101000a900473ffffffffffffffffffffffffffffffffffffffff168a6040518363ffffffff1660e01b8152600401611260929190611fb4565b60206040518083038186803b15801561127857600080fd5b505afa15801561128c573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906112b09190611ff2565b600660008b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905590505b82611309838561104990919063ffffffff16565b8383965096509650965050505092959194509250565b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff16141561138f576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016113869061206b565b60405180910390fd5b61139b6000838361147f565b80600260008282546113ad9190611aa4565b92505081905550806000808473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546114029190611aa4565b925050819055508173ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8360405161146791906117ce565b60405180910390a361147b60008383611484565b5050565b505050565b505050565b60006114a2633b9aca00836115c990919063ffffffff16565b9050919050565b60006115066b033b2e3c9fd0803ce80000006114f86114d185876115c990919063ffffffff16565b60026b033b2e3c9fd0803ce80000006114ea91906120ba565b61104990919063ffffffff16565b6115df90919063ffffffff16565b905092915050565b60008060028361151e91906120ba565b9050611563836115556115466b033b2e3c9fd0803ce8000000886115c990919063ffffffff16565b8461104990919063ffffffff16565b6115df90919063ffffffff16565b91505092915050565b6000806002633b9aca0061158091906120ba565b90506115ab633b9aca0061159d858461104990919063ffffffff16565b6115df90919063ffffffff16565b915050919050565b600081836115c191906120eb565b905092915050565b600081836115d7919061211f565b905092915050565b600081836115ed91906120ba565b905092915050565b600081519050919050565b600082825260208201905092915050565b60005b8381101561162f578082015181840152602081019050611614565b8381111561163e576000848401525b50505050565b6000601f19601f8301169050919050565b6000611660826115f5565b61166a8185611600565b935061167a818560208601611611565b61168381611644565b840191505092915050565b600060208201905081810360008301526116a88184611655565b905092915050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006116e0826116b5565b9050919050565b6116f0816116d5565b81146116fb57600080fd5b50565b60008135905061170d816116e7565b92915050565b6000819050919050565b61172681611713565b811461173157600080fd5b50565b6000813590506117438161171d565b92915050565b600080604083850312156117605761175f6116b0565b5b600061176e858286016116fe565b925050602061177f85828601611734565b9150509250929050565b60008115159050919050565b61179e81611789565b82525050565b60006020820190506117b96000830184611795565b92915050565b6117c881611713565b82525050565b60006020820190506117e360008301846117bf565b92915050565b600080600060608486031215611802576118016116b0565b5b6000611810868287016116fe565b9350506020611821868287016116fe565b925050604061183286828701611734565b9150509250925092565b600060ff82169050919050565b6118528161183c565b82525050565b600060208201905061186d6000830184611849565b92915050565b600060208284031215611889576118886116b0565b5b6000611897848285016116fe565b91505092915050565b6118a9816116d5565b82525050565b60006020820190506118c460008301846118a0565b92915050565b600281106118d757600080fd5b50565b6000813590506118e9816118ca565b92915050565b600080600060608486031215611908576119076116b0565b5b6000611916868287016116fe565b9350506020611927868287016118da565b925050604061193886828701611734565b9150509250925092565b60008060408385031215611959576119586116b0565b5b6000611967858286016116fe565b9250506020611978858286016116fe565b9150509250929050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b600060028204905060018216806119c957607f821691505b602082108114156119dd576119dc611982565b5b50919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206160008201527f6c6c6f77616e6365000000000000000000000000000000000000000000000000602082015250565b6000611a3f602883611600565b9150611a4a826119e3565b604082019050919050565b60006020820190508181036000830152611a6e81611a32565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000611aaf82611713565b9150611aba83611713565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115611aef57611aee611a75565b5b828201905092915050565b7f5468652063616c6c6572206f6620746869732066756e6374696f6e206d75737460008201527f206265206c69717569646974794d616e61676572000000000000000000000000602082015250565b6000611b56603483611600565b9150611b6182611afa565b604082019050919050565b60006020820190508181036000830152611b8581611b49565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b60028110611bcc57611bcb611b8c565b5b50565b6000819050611bdd82611bbb565b919050565b6000611bed82611bcf565b9050919050565b611bfd81611be2565b82525050565b6000608082019050611c1860008301876117bf565b611c2560208301866117bf565b611c3260408301856117bf565b611c3f6060830184611bf4565b95945050505050565b7f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f7760008201527f207a65726f000000000000000000000000000000000000000000000000000000602082015250565b6000611ca4602583611600565b9150611caf82611c48565b604082019050919050565b60006020820190508181036000830152611cd381611c97565b9050919050565b7f45524332303a20617070726f76652066726f6d20746865207a65726f2061646460008201527f7265737300000000000000000000000000000000000000000000000000000000602082015250565b6000611d36602483611600565b9150611d4182611cda565b604082019050919050565b60006020820190508181036000830152611d6581611d29565b9050919050565b7f45524332303a20617070726f766520746f20746865207a65726f20616464726560008201527f7373000000000000000000000000000000000000000000000000000000000000602082015250565b6000611dc8602283611600565b9150611dd382611d6c565b604082019050919050565b60006020820190508181036000830152611df781611dbb565b9050919050565b7f45524332303a207472616e736665722066726f6d20746865207a65726f20616460008201527f6472657373000000000000000000000000000000000000000000000000000000602082015250565b6000611e5a602583611600565b9150611e6582611dfe565b604082019050919050565b60006020820190508181036000830152611e8981611e4d565b9050919050565b7f45524332303a207472616e7366657220746f20746865207a65726f206164647260008201527f6573730000000000000000000000000000000000000000000000000000000000602082015250565b6000611eec602383611600565b9150611ef782611e90565b604082019050919050565b60006020820190508181036000830152611f1b81611edf565b9050919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206260008201527f616c616e63650000000000000000000000000000000000000000000000000000602082015250565b6000611f7e602683611600565b9150611f8982611f22565b604082019050919050565b60006020820190508181036000830152611fad81611f71565b9050919050565b6000604082019050611fc960008301856118a0565b611fd66020830184611bf4565b9392505050565b600081519050611fec8161171d565b92915050565b600060208284031215612008576120076116b0565b5b600061201684828501611fdd565b91505092915050565b7f45524332303a206d696e7420746f20746865207a65726f206164647265737300600082015250565b6000612055601f83611600565b91506120608261201f565b602082019050919050565b6000602082019050818103600083015261208481612048565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b60006120c582611713565b91506120d083611713565b9250826120e0576120df61208b565b5b828204905092915050565b60006120f682611713565b915061210183611713565b92508282101561211457612113611a75565b5b828203905092915050565b600061212a82611713565b915061213583611713565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff048311821515161561216e5761216d611a75565b5b82820290509291505056fea2646970667358221220fb0f2c42c8085b33dfa78cbc63fc110b077012a03e74731ecd93917321197c4364736f6c63430008090033";

export class VToken__factory extends ContractFactory {
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
    _underlyingAssetDecimals: BigNumberish,
    _name: string,
    _symbol: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<VToken> {
    return super.deploy(
      _underlyingAsset,
      _underlyingAssetDecimals,
      _name,
      _symbol,
      overrides || {}
    ) as Promise<VToken>;
  }
  getDeployTransaction(
    _underlyingAsset: string,
    _underlyingAssetDecimals: BigNumberish,
    _name: string,
    _symbol: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _underlyingAsset,
      _underlyingAssetDecimals,
      _name,
      _symbol,
      overrides || {}
    );
  }
  attach(address: string): VToken {
    return super.attach(address) as VToken;
  }
  connect(signer: Signer): VToken__factory {
    return super.connect(signer) as VToken__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): VTokenInterface {
    return new utils.Interface(_abi) as VTokenInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): VToken {
    return new Contract(address, _abi, signerOrProvider) as VToken;
  }
}

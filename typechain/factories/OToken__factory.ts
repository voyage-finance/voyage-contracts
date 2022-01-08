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
    inputs: [
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "redeem",
    outputs: [],
    stateMutability: "nonpayable",
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
  "0x60806040523480156200001157600080fd5b50604051620019dd380380620019dd833981810160405281019062000037919062000328565b818181600390805190602001906200005192919062000076565b5080600490805190602001906200006a92919062000076565b50505050505062000427565b8280546200008490620003f1565b90600052602060002090601f016020900481019282620000a85760008555620000f4565b82601f10620000c357805160ff1916838001178555620000f4565b82800160010185558215620000f4579182015b82811115620000f3578251825591602001919060010190620000d6565b5b50905062000103919062000107565b5090565b5b808211156200012257600081600090555060010162000108565b5090565b6000604051905090565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600062000167826200013a565b9050919050565b62000179816200015a565b81146200018557600080fd5b50565b60008151905062000199816200016e565b92915050565b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b620001f482620001a9565b810181811067ffffffffffffffff82111715620002165762000215620001ba565b5b80604052505050565b60006200022b62000126565b9050620002398282620001e9565b919050565b600067ffffffffffffffff8211156200025c576200025b620001ba565b5b6200026782620001a9565b9050602081019050919050565b60005b838110156200029457808201518184015260208101905062000277565b83811115620002a4576000848401525b50505050565b6000620002c1620002bb846200023e565b6200021f565b905082815260208101848484011115620002e057620002df620001a4565b5b620002ed84828562000274565b509392505050565b600082601f8301126200030d576200030c6200019f565b5b81516200031f848260208601620002aa565b91505092915050565b60008060006060848603121562000344576200034362000130565b5b6000620003548682870162000188565b935050602084015167ffffffffffffffff81111562000378576200037762000135565b5b6200038686828701620002f5565b925050604084015167ffffffffffffffff811115620003aa57620003a962000135565b5b620003b886828701620002f5565b9150509250925092565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b600060028204905060018216806200040a57607f821691505b60208210811415620004215762000420620003c2565b5b50919050565b6115a680620004376000396000f3fe608060405234801561001057600080fd5b50600436106100ea5760003560e01c806389d1a0fc1161008c578063a457c2d711610066578063a457c2d714610261578063a9059cbb14610291578063db006a75146102c1578063dd62ed3e146102dd576100ea565b806389d1a0fc1461020957806394362e8b1461022757806395d89b4114610243576100ea565b806323b872dd116100c857806323b872dd1461015b578063313ce5671461018b57806339509351146101a957806370a08231146101d9576100ea565b806306fdde03146100ef578063095ea7b31461010d57806318160ddd1461013d575b600080fd5b6100f761030d565b6040516101049190610d51565b60405180910390f35b61012760048036038101906101229190610e0c565b61039f565b6040516101349190610e67565b60405180910390f35b6101456103bd565b6040516101529190610e91565b60405180910390f35b61017560048036038101906101709190610eac565b6103c7565b6040516101829190610e67565b60405180910390f35b6101936104bf565b6040516101a09190610f1b565b60405180910390f35b6101c360048036038101906101be9190610e0c565b6104c8565b6040516101d09190610e67565b60405180910390f35b6101f360048036038101906101ee9190610f36565b610574565b6040516102009190610e91565b60405180910390f35b61021161057b565b60405161021e9190610f72565b60405180910390f35b610241600480360381019061023c9190610e0c565b6105a1565b005b61024b610635565b6040516102589190610d51565b60405180910390f35b61027b60048036038101906102769190610e0c565b6106c7565b6040516102889190610e67565b60405180910390f35b6102ab60048036038101906102a69190610e0c565b6107b2565b6040516102b89190610e67565b60405180910390f35b6102db60048036038101906102d69190610f8d565b6107d0565b005b6102f760048036038101906102f29190610fba565b6107d3565b6040516103049190610e91565b60405180910390f35b60606003805461031c90611029565b80601f016020809104026020016040519081016040528092919081815260200182805461034890611029565b80156103955780601f1061036a57610100808354040283529160200191610395565b820191906000526020600020905b81548152906001019060200180831161037857829003601f168201915b5050505050905090565b60006103b36103ac61085a565b8484610862565b6001905092915050565b6000600254905090565b60006103d4848484610a2d565b6000600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600061041f61085a565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205490508281101561049f576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610496906110cd565b60405180910390fd5b6104b3856104ab61085a565b858403610862565b60019150509392505050565b60006012905090565b600061056a6104d561085a565b8484600160006104e361085a565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054610565919061111c565b610862565b6001905092915050565b6000919050565b600560009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600660009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610631576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610628906111e4565b60405180910390fd5b5050565b60606004805461064490611029565b80601f016020809104026020016040519081016040528092919081815260200182805461067090611029565b80156106bd5780601f10610692576101008083540402835291602001916106bd565b820191906000526020600020905b8154815290600101906020018083116106a057829003601f168201915b5050505050905090565b600080600160006106d661085a565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905082811015610793576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161078a90611276565b60405180910390fd5b6107a761079e61085a565b85858403610862565b600191505092915050565b60006107c66107bf61085a565b8484610a2d565b6001905092915050565b50565b6000600160008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905092915050565b600033905090565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614156108d2576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016108c990611308565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415610942576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016109399061139a565b60405180910390fd5b80600160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92583604051610a209190610e91565b60405180910390a3505050565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415610a9d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610a949061142c565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415610b0d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b04906114be565b60405180910390fd5b610b18838383610cae565b60008060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905081811015610b9e576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b9590611550565b60405180910390fd5b8181036000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550816000808573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610c31919061111c565b925050819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef84604051610c959190610e91565b60405180910390a3610ca8848484610cb3565b50505050565b505050565b505050565b600081519050919050565b600082825260208201905092915050565b60005b83811015610cf2578082015181840152602081019050610cd7565b83811115610d01576000848401525b50505050565b6000601f19601f8301169050919050565b6000610d2382610cb8565b610d2d8185610cc3565b9350610d3d818560208601610cd4565b610d4681610d07565b840191505092915050565b60006020820190508181036000830152610d6b8184610d18565b905092915050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610da382610d78565b9050919050565b610db381610d98565b8114610dbe57600080fd5b50565b600081359050610dd081610daa565b92915050565b6000819050919050565b610de981610dd6565b8114610df457600080fd5b50565b600081359050610e0681610de0565b92915050565b60008060408385031215610e2357610e22610d73565b5b6000610e3185828601610dc1565b9250506020610e4285828601610df7565b9150509250929050565b60008115159050919050565b610e6181610e4c565b82525050565b6000602082019050610e7c6000830184610e58565b92915050565b610e8b81610dd6565b82525050565b6000602082019050610ea66000830184610e82565b92915050565b600080600060608486031215610ec557610ec4610d73565b5b6000610ed386828701610dc1565b9350506020610ee486828701610dc1565b9250506040610ef586828701610df7565b9150509250925092565b600060ff82169050919050565b610f1581610eff565b82525050565b6000602082019050610f306000830184610f0c565b92915050565b600060208284031215610f4c57610f4b610d73565b5b6000610f5a84828501610dc1565b91505092915050565b610f6c81610d98565b82525050565b6000602082019050610f876000830184610f63565b92915050565b600060208284031215610fa357610fa2610d73565b5b6000610fb184828501610df7565b91505092915050565b60008060408385031215610fd157610fd0610d73565b5b6000610fdf85828601610dc1565b9250506020610ff085828601610dc1565b9150509250929050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b6000600282049050600182168061104157607f821691505b6020821081141561105557611054610ffa565b5b50919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206160008201527f6c6c6f77616e6365000000000000000000000000000000000000000000000000602082015250565b60006110b7602883610cc3565b91506110c28261105b565b604082019050919050565b600060208201905081810360008301526110e6816110aa565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b600061112782610dd6565b915061113283610dd6565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115611167576111666110ed565b5b828201905092915050565b7f5468652063616c6c6572206f6620746869732066756e6374696f6e206d75737460008201527f206265204f776e66740000000000000000000000000000000000000000000000602082015250565b60006111ce602983610cc3565b91506111d982611172565b604082019050919050565b600060208201905081810360008301526111fd816111c1565b9050919050565b7f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f7760008201527f207a65726f000000000000000000000000000000000000000000000000000000602082015250565b6000611260602583610cc3565b915061126b82611204565b604082019050919050565b6000602082019050818103600083015261128f81611253565b9050919050565b7f45524332303a20617070726f76652066726f6d20746865207a65726f2061646460008201527f7265737300000000000000000000000000000000000000000000000000000000602082015250565b60006112f2602483610cc3565b91506112fd82611296565b604082019050919050565b60006020820190508181036000830152611321816112e5565b9050919050565b7f45524332303a20617070726f766520746f20746865207a65726f20616464726560008201527f7373000000000000000000000000000000000000000000000000000000000000602082015250565b6000611384602283610cc3565b915061138f82611328565b604082019050919050565b600060208201905081810360008301526113b381611377565b9050919050565b7f45524332303a207472616e736665722066726f6d20746865207a65726f20616460008201527f6472657373000000000000000000000000000000000000000000000000000000602082015250565b6000611416602583610cc3565b9150611421826113ba565b604082019050919050565b6000602082019050818103600083015261144581611409565b9050919050565b7f45524332303a207472616e7366657220746f20746865207a65726f206164647260008201527f6573730000000000000000000000000000000000000000000000000000000000602082015250565b60006114a8602383610cc3565b91506114b38261144c565b604082019050919050565b600060208201905081810360008301526114d78161149b565b9050919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206260008201527f616c616e63650000000000000000000000000000000000000000000000000000602082015250565b600061153a602683610cc3565b9150611545826114de565b604082019050919050565b600060208201905081810360008301526115698161152d565b905091905056fea264697066735822122028b9f704747373ccd0f56cb36754721b1b4ed6a95bfa47ebd791a4951fbdf60664736f6c63430008090033";

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

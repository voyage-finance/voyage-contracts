/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Main, MainInterface } from "../Main";

const _abi = [
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
        internalType: "uint8",
        name: "_underlyingAssetDecimals",
        type: "uint8",
      },
      {
        internalType: "address",
        name: "_interestRateStrategyAddress",
        type: "address",
      },
      {
        internalType: "enum CoreLibrary.Tranche",
        name: "tranche",
        type: "uint8",
      },
    ],
    name: "initReserve",
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
        internalType: "string",
        name: "_oTokenName",
        type: "string",
      },
      {
        internalType: "string",
        name: "_oTokenSymbol",
        type: "string",
      },
      {
        internalType: "uint8",
        name: "_underlyingAssetDecimals",
        type: "uint8",
      },
      {
        internalType: "address",
        name: "_interestRateStrategyAddress",
        type: "address",
      },
      {
        internalType: "enum CoreLibrary.Tranche",
        name: "tranche",
        type: "uint8",
      },
    ],
    name: "initReserveWithData",
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
  "0x608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a360016002819055506129b8806100e36000396000f3fe60806040523480156200001157600080fd5b5060043610620000885760003560e01c80638da5cb5b11620000635780638da5cb5b14620000d95780638f32d59b14620000fb578063e30c3978146200011d578063f2fde38b146200013f5762000088565b8063078d0443146200008d5780634e71e0c814620000ad5780637d003caa14620000b9575b600080fd5b620000ab6004803603810190620000a5919062000802565b6200015f565b005b620000b762000368565b005b620000d76004803603810190620000d19190620009d6565b62000505565b005b620000e3620005e4565b604051620000f2919062000ac1565b60405180910390f35b6200010562000608565b60405162000114919062000afb565b60405180910390f35b620001276200065f565b60405162000136919062000ac1565b60405180910390f35b6200015d600480360381019062000157919062000b18565b62000685565b005b3373ffffffffffffffffffffffffffffffffffffffff16600460009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1614620001f2576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620001e99062000bd1565b60405180910390fd5b600084905060008173ffffffffffffffffffffffffffffffffffffffff166306fdde036040518163ffffffff1660e01b815260040160006040518083038186803b1580156200024057600080fd5b505afa15801562000255573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f8201168201806040525081019062000280919062000ca7565b60405160200162000292919062000d95565b604051602081830303815290604052905060008273ffffffffffffffffffffffffffffffffffffffff166395d89b416040518163ffffffff1660e01b815260040160006040518083038186803b158015620002ec57600080fd5b505afa15801562000301573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f820116820180604052508101906200032c919062000ca7565b6040516020016200033e919062000e0b565b60405160208183030381529060405290506200035f87838389898962000505565b50505050505050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614620003c357600080fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff166000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b3373ffffffffffffffffffffffffffffffffffffffff16600460009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff161462000598576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016200058f9062000bd1565b60405180910390fd5b600086848787604051620005ac9062000715565b620005bb949392919062000e83565b604051809103906000f080158015620005d8573d6000803e3d6000fd5b50905050505050505050565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614905090565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6200068f62000608565b620006d1576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620006c89062000f2e565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b611a328062000f5183390190565b6000604051905090565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000620007648262000737565b9050919050565b620007768162000757565b81146200078257600080fd5b50565b60008135905062000796816200076b565b92915050565b600060ff82169050919050565b620007b4816200079c565b8114620007c057600080fd5b50565b600081359050620007d481620007a9565b92915050565b60028110620007e857600080fd5b50565b600081359050620007fc81620007da565b92915050565b600080600080608085870312156200081f576200081e6200072d565b5b60006200082f8782880162000785565b94505060206200084287828801620007c3565b9350506040620008558782880162000785565b92505060606200086887828801620007eb565b91505092959194509250565b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b620008c9826200087e565b810181811067ffffffffffffffff82111715620008eb57620008ea6200088f565b5b80604052505050565b60006200090062000723565b90506200090e8282620008be565b919050565b600067ffffffffffffffff8211156200093157620009306200088f565b5b6200093c826200087e565b9050602081019050919050565b82818337600083830152505050565b60006200096f620009698462000913565b620008f4565b9050828152602081018484840111156200098e576200098d62000879565b5b6200099b84828562000949565b509392505050565b600082601f830112620009bb57620009ba62000874565b5b8135620009cd84826020860162000958565b91505092915050565b60008060008060008060c08789031215620009f657620009f56200072d565b5b600062000a0689828a0162000785565b965050602087013567ffffffffffffffff81111562000a2a5762000a2962000732565b5b62000a3889828a01620009a3565b955050604087013567ffffffffffffffff81111562000a5c5762000a5b62000732565b5b62000a6a89828a01620009a3565b945050606062000a7d89828a01620007c3565b935050608062000a9089828a0162000785565b92505060a062000aa389828a01620007eb565b9150509295509295509295565b62000abb8162000757565b82525050565b600060208201905062000ad8600083018462000ab0565b92915050565b60008115159050919050565b62000af58162000ade565b82525050565b600060208201905062000b12600083018462000aea565b92915050565b60006020828403121562000b315762000b306200072d565b5b600062000b418482850162000785565b91505092915050565b600082825260208201905092915050565b7f5468652063616c6c6572206d7573742062652061206c656e64696e6720706f6f60008201527f6c206d616e616765720000000000000000000000000000000000000000000000602082015250565b600062000bb960298362000b4a565b915062000bc68262000b5b565b604082019050919050565b6000602082019050818103600083015262000bec8162000baa565b9050919050565b60005b8381101562000c1357808201518184015260208101905062000bf6565b8381111562000c23576000848401525b50505050565b600062000c4062000c3a8462000913565b620008f4565b90508281526020810184848401111562000c5f5762000c5e62000879565b5b62000c6c84828562000bf3565b509392505050565b600082601f83011262000c8c5762000c8b62000874565b5b815162000c9e84826020860162000c29565b91505092915050565b60006020828403121562000cc05762000cbf6200072d565b5b600082015167ffffffffffffffff81111562000ce15762000ce062000732565b5b62000cef8482850162000c74565b91505092915050565b600081905092915050565b7f4f776e667420496e7465726573742062656172696e6720000000000000000000600082015250565b600062000d3b60178362000cf8565b915062000d488262000d03565b601782019050919050565b600081519050919050565b600062000d6b8262000d53565b62000d77818562000cf8565b935062000d8981856020860162000bf3565b80840191505092915050565b600062000da28262000d2c565b915062000db0828462000d5e565b915081905092915050565b7f6100000000000000000000000000000000000000000000000000000000000000600082015250565b600062000df360018362000cf8565b915062000e008262000dbb565b600182019050919050565b600062000e188262000de4565b915062000e26828462000d5e565b915081905092915050565b62000e3c816200079c565b82525050565b600062000e4f8262000d53565b62000e5b818562000b4a565b935062000e6d81856020860162000bf3565b62000e78816200087e565b840191505092915050565b600060808201905062000e9a600083018762000ab0565b62000ea9602083018662000e31565b818103604083015262000ebd818562000e42565b9050818103606083015262000ed3818462000e42565b905095945050505050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b600062000f1660208362000b4a565b915062000f238262000ede565b602082019050919050565b6000602082019050818103600083015262000f498162000f07565b905091905056fe60806040523480156200001157600080fd5b5060405162001a3238038062001a32833981810160405281019062000037919062000367565b818181600390805190602001906200005192919062000077565b5080600490805190602001906200006a92919062000077565b505050505050506200047c565b828054620000859062000446565b90600052602060002090601f016020900481019282620000a95760008555620000f5565b82601f10620000c457805160ff1916838001178555620000f5565b82800160010185558215620000f5579182015b82811115620000f4578251825591602001919060010190620000d7565b5b50905062000104919062000108565b5090565b5b808211156200012357600081600090555060010162000109565b5090565b6000604051905090565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600062000168826200013b565b9050919050565b6200017a816200015b565b81146200018657600080fd5b50565b6000815190506200019a816200016f565b92915050565b600060ff82169050919050565b620001b881620001a0565b8114620001c457600080fd5b50565b600081519050620001d881620001ad565b92915050565b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6200023382620001e8565b810181811067ffffffffffffffff82111715620002555762000254620001f9565b5b80604052505050565b60006200026a62000127565b905062000278828262000228565b919050565b600067ffffffffffffffff8211156200029b576200029a620001f9565b5b620002a682620001e8565b9050602081019050919050565b60005b83811015620002d3578082015181840152602081019050620002b6565b83811115620002e3576000848401525b50505050565b600062000300620002fa846200027d565b6200025e565b9050828152602081018484840111156200031f576200031e620001e3565b5b6200032c848285620002b3565b509392505050565b600082601f8301126200034c576200034b620001de565b5b81516200035e848260208601620002e9565b91505092915050565b6000806000806080858703121562000384576200038362000131565b5b6000620003948782880162000189565b9450506020620003a787828801620001c7565b935050604085015167ffffffffffffffff811115620003cb57620003ca62000136565b5b620003d98782880162000334565b925050606085015167ffffffffffffffff811115620003fd57620003fc62000136565b5b6200040b8782880162000334565b91505092959194509250565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b600060028204905060018216806200045f57607f821691505b6020821081141562000476576200047562000417565b5b50919050565b6115a6806200048c6000396000f3fe608060405234801561001057600080fd5b50600436106100ea5760003560e01c806389d1a0fc1161008c578063a457c2d711610066578063a457c2d714610261578063a9059cbb14610291578063db006a75146102c1578063dd62ed3e146102dd576100ea565b806389d1a0fc1461020957806394362e8b1461022757806395d89b4114610243576100ea565b806323b872dd116100c857806323b872dd1461015b578063313ce5671461018b57806339509351146101a957806370a08231146101d9576100ea565b806306fdde03146100ef578063095ea7b31461010d57806318160ddd1461013d575b600080fd5b6100f761030d565b6040516101049190610d51565b60405180910390f35b61012760048036038101906101229190610e0c565b61039f565b6040516101349190610e67565b60405180910390f35b6101456103bd565b6040516101529190610e91565b60405180910390f35b61017560048036038101906101709190610eac565b6103c7565b6040516101829190610e67565b60405180910390f35b6101936104bf565b6040516101a09190610f1b565b60405180910390f35b6101c360048036038101906101be9190610e0c565b6104c8565b6040516101d09190610e67565b60405180910390f35b6101f360048036038101906101ee9190610f36565b610574565b6040516102009190610e91565b60405180910390f35b61021161057b565b60405161021e9190610f72565b60405180910390f35b610241600480360381019061023c9190610e0c565b6105a1565b005b61024b610635565b6040516102589190610d51565b60405180910390f35b61027b60048036038101906102769190610e0c565b6106c7565b6040516102889190610e67565b60405180910390f35b6102ab60048036038101906102a69190610e0c565b6107b2565b6040516102b89190610e67565b60405180910390f35b6102db60048036038101906102d69190610f8d565b6107d0565b005b6102f760048036038101906102f29190610fba565b6107d3565b6040516103049190610e91565b60405180910390f35b60606003805461031c90611029565b80601f016020809104026020016040519081016040528092919081815260200182805461034890611029565b80156103955780601f1061036a57610100808354040283529160200191610395565b820191906000526020600020905b81548152906001019060200180831161037857829003601f168201915b5050505050905090565b60006103b36103ac61085a565b8484610862565b6001905092915050565b6000600254905090565b60006103d4848484610a2d565b6000600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600061041f61085a565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205490508281101561049f576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610496906110cd565b60405180910390fd5b6104b3856104ab61085a565b858403610862565b60019150509392505050565b60006012905090565b600061056a6104d561085a565b8484600160006104e361085a565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054610565919061111c565b610862565b6001905092915050565b6000919050565b600660009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600760009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610631576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610628906111e4565b60405180910390fd5b5050565b60606004805461064490611029565b80601f016020809104026020016040519081016040528092919081815260200182805461067090611029565b80156106bd5780601f10610692576101008083540402835291602001916106bd565b820191906000526020600020905b8154815290600101906020018083116106a057829003601f168201915b5050505050905090565b600080600160006106d661085a565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905082811015610793576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161078a90611276565b60405180910390fd5b6107a761079e61085a565b85858403610862565b600191505092915050565b60006107c66107bf61085a565b8484610a2d565b6001905092915050565b50565b6000600160008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905092915050565b600033905090565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614156108d2576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016108c990611308565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415610942576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016109399061139a565b60405180910390fd5b80600160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92583604051610a209190610e91565b60405180910390a3505050565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415610a9d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610a949061142c565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415610b0d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b04906114be565b60405180910390fd5b610b18838383610cae565b60008060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905081811015610b9e576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b9590611550565b60405180910390fd5b8181036000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550816000808573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610c31919061111c565b925050819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef84604051610c959190610e91565b60405180910390a3610ca8848484610cb3565b50505050565b505050565b505050565b600081519050919050565b600082825260208201905092915050565b60005b83811015610cf2578082015181840152602081019050610cd7565b83811115610d01576000848401525b50505050565b6000601f19601f8301169050919050565b6000610d2382610cb8565b610d2d8185610cc3565b9350610d3d818560208601610cd4565b610d4681610d07565b840191505092915050565b60006020820190508181036000830152610d6b8184610d18565b905092915050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610da382610d78565b9050919050565b610db381610d98565b8114610dbe57600080fd5b50565b600081359050610dd081610daa565b92915050565b6000819050919050565b610de981610dd6565b8114610df457600080fd5b50565b600081359050610e0681610de0565b92915050565b60008060408385031215610e2357610e22610d73565b5b6000610e3185828601610dc1565b9250506020610e4285828601610df7565b9150509250929050565b60008115159050919050565b610e6181610e4c565b82525050565b6000602082019050610e7c6000830184610e58565b92915050565b610e8b81610dd6565b82525050565b6000602082019050610ea66000830184610e82565b92915050565b600080600060608486031215610ec557610ec4610d73565b5b6000610ed386828701610dc1565b9350506020610ee486828701610dc1565b9250506040610ef586828701610df7565b9150509250925092565b600060ff82169050919050565b610f1581610eff565b82525050565b6000602082019050610f306000830184610f0c565b92915050565b600060208284031215610f4c57610f4b610d73565b5b6000610f5a84828501610dc1565b91505092915050565b610f6c81610d98565b82525050565b6000602082019050610f876000830184610f63565b92915050565b600060208284031215610fa357610fa2610d73565b5b6000610fb184828501610df7565b91505092915050565b60008060408385031215610fd157610fd0610d73565b5b6000610fdf85828601610dc1565b9250506020610ff085828601610dc1565b9150509250929050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b6000600282049050600182168061104157607f821691505b6020821081141561105557611054610ffa565b5b50919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206160008201527f6c6c6f77616e6365000000000000000000000000000000000000000000000000602082015250565b60006110b7602883610cc3565b91506110c28261105b565b604082019050919050565b600060208201905081810360008301526110e6816110aa565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b600061112782610dd6565b915061113283610dd6565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115611167576111666110ed565b5b828201905092915050565b7f5468652063616c6c6572206f6620746869732066756e6374696f6e206d75737460008201527f206265204f776e66740000000000000000000000000000000000000000000000602082015250565b60006111ce602983610cc3565b91506111d982611172565b604082019050919050565b600060208201905081810360008301526111fd816111c1565b9050919050565b7f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f7760008201527f207a65726f000000000000000000000000000000000000000000000000000000602082015250565b6000611260602583610cc3565b915061126b82611204565b604082019050919050565b6000602082019050818103600083015261128f81611253565b9050919050565b7f45524332303a20617070726f76652066726f6d20746865207a65726f2061646460008201527f7265737300000000000000000000000000000000000000000000000000000000602082015250565b60006112f2602483610cc3565b91506112fd82611296565b604082019050919050565b60006020820190508181036000830152611321816112e5565b9050919050565b7f45524332303a20617070726f766520746f20746865207a65726f20616464726560008201527f7373000000000000000000000000000000000000000000000000000000000000602082015250565b6000611384602283610cc3565b915061138f82611328565b604082019050919050565b600060208201905081810360008301526113b381611377565b9050919050565b7f45524332303a207472616e736665722066726f6d20746865207a65726f20616460008201527f6472657373000000000000000000000000000000000000000000000000000000602082015250565b6000611416602583610cc3565b9150611421826113ba565b604082019050919050565b6000602082019050818103600083015261144581611409565b9050919050565b7f45524332303a207472616e7366657220746f20746865207a65726f206164647260008201527f6573730000000000000000000000000000000000000000000000000000000000602082015250565b60006114a8602383610cc3565b91506114b38261144c565b604082019050919050565b600060208201905081810360008301526114d78161149b565b9050919050565b7f45524332303a207472616e7366657220616d6f756e742065786365656473206260008201527f616c616e63650000000000000000000000000000000000000000000000000000602082015250565b600061153a602683610cc3565b9150611545826114de565b604082019050919050565b600060208201905081810360008301526115698161152d565b905091905056fea264697066735822122071cc4ac38de6ce2f799df4522e6eacd49d4854c29f1c87e6e3c3ec14e032d89064736f6c63430008090033a264697066735822122031922dbd362af3ff631236c8ea43c7705955017a85143977acd7b3af35980be064736f6c63430008090033";

export class Main__factory extends ContractFactory {
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
  ): Promise<Main> {
    return super.deploy(overrides || {}) as Promise<Main>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): Main {
    return super.attach(address) as Main;
  }
  connect(signer: Signer): Main__factory {
    return super.connect(signer) as Main__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MainInterface {
    return new utils.Interface(_abi) as MainInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Main {
    return new Contract(address, _abi, signerOrProvider) as Main;
  }
}

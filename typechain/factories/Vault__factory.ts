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
    inputs: [
      {
        internalType: "address",
        name: "_reserve",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "depositSecurity",
    outputs: [],
    stateMutability: "payable",
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
    name: "getCurrentSecurityDeposit",
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
    inputs: [],
    name: "getSecurityDepositEscrowAddress",
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
    name: "getVersion",
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
        name: "_voyager",
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
    inputs: [],
    name: "securityDepositEscrow",
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
  {
    inputs: [],
    name: "voyager",
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
  "0x60806040523480156200001157600080fd5b506001808190555033600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000336040516020016200006f91906200019b565b6040516020818303038152906040528051906020012090506000604051806020016200009b9062000109565b6020820181038252601f19601f8201166040525090506000828251602084016000f5905080600560006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550505050620001b8565b61201d80620019c483390190565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000620001448262000117565b9050919050565b60008160601b9050919050565b600062000165826200014b565b9050919050565b6000620001798262000158565b9050919050565b620001956200018f8262000137565b6200016c565b82525050565b6000620001a9828462000180565b60148201915081905092915050565b6117fc80620001c86000396000f3fe6080604052600436106100fe5760003560e01c8063915d34c711610095578063c45a015511610064578063c45a015514610328578063d547741f14610353578063f448e1401461037c578063f71d96cb146103a7578063f740c8c5146103e4576100fe565b8063915d34c71461027957806391d14854146102a4578063a1842b24146102e1578063a217fddf146102fd576100fe565b8063248a9ca3116100d1578063248a9ca3146101c15780632f2ff15d146101fe57806336568abe14610227578063485cc95514610250576100fe565b806301ffc9a714610103578063065d570f146101405780630a8d69b01461016b5780630d8e6e2c14610196575b600080fd5b34801561010f57600080fd5b5061012a60048036038101906101259190610f59565b610421565b6040516101379190610fa1565b60405180910390f35b34801561014c57600080fd5b5061015561049b565b6040516101629190610fd5565b60405180910390f35b34801561017757600080fd5b506101806104bf565b60405161018d9190611031565b60405180910390f35b3480156101a257600080fd5b506101ab6104e9565b6040516101b891906110e5565b60405180910390f35b3480156101cd57600080fd5b506101e860048036038101906101e39190611133565b61052c565b6040516101f59190610fd5565b60405180910390f35b34801561020a57600080fd5b506102256004803603810190610220919061118c565b61054b565b005b34801561023357600080fd5b5061024e6004803603810190610249919061118c565b610574565b005b34801561025c57600080fd5b50610277600480360381019061027291906111cc565b6105f7565b005b34801561028557600080fd5b5061028e6106f6565b60405161029b9190611031565b60405180910390f35b3480156102b057600080fd5b506102cb60048036038101906102c6919061118c565b61071c565b6040516102d89190610fa1565b60405180910390f35b6102fb60048036038101906102f69190611242565b610786565b005b34801561030957600080fd5b50610312610870565b60405161031f9190610fd5565b60405180910390f35b34801561033457600080fd5b5061033d610877565b60405161034a9190611031565b60405180910390f35b34801561035f57600080fd5b5061037a6004803603810190610375919061118c565b61089d565b005b34801561038857600080fd5b506103916108c6565b60405161039e9190611031565b60405180910390f35b3480156103b357600080fd5b506103ce60048036038101906103c99190611282565b6108ec565b6040516103db9190611031565b60405180910390f35b3480156103f057600080fd5b5061040b600480360381019061040691906111cc565b61092b565b60405161041891906112be565b60405180910390f35b60007f7965db0b000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff191614806104945750610493826109e2565b5b9050919050565b7fbf87e2252b7172d9c61058578b6bef80f9573784ab4e27044251da25a76ed28e81565b6000600560009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b606060006040518060400160405280600b81526020017f5661756c7420302e302e3100000000000000000000000000000000000000000081525090508091505090565b6000806000838152602001908152602001600020600101549050919050565b6105548261052c565b61056581610560610a4c565b610a54565b61056f8383610af1565b505050565b61057c610a4c565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16146105e9576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105e09061134b565b60405180910390fd5b6105f38282610bd1565b5050565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610687576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161067e906113b7565b60405180910390fd5b81600360006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506106f27fbf87e2252b7172d9c61058578b6bef80f9573784ab4e27044251da25a76ed28e82610cb2565b5050565b600560009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600080600084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16905092915050565b600260015414156107cc576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016107c390611423565b60405180910390fd5b6002600181905550600560009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16638340f5498333846040518463ffffffff1660e01b815260040161083393929190611443565b600060405180830381600087803b15801561084d57600080fd5b505af1158015610861573d6000803e3d6000fd5b50505050600180819055505050565b6000801b81565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6108a68261052c565b6108b7816108b2610a4c565b610a54565b6108c18383610bd1565b505050565b600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600481815481106108fc57600080fd5b906000526020600020016000915054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6000600560009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663f45b1b3a84846040518363ffffffff1660e01b815260040161098a92919061147a565b60206040518083038186803b1580156109a257600080fd5b505afa1580156109b6573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906109da91906114b8565b905092915050565b60007f01ffc9a7000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916149050919050565b600033905090565b610a5e828261071c565b610aed57610a838173ffffffffffffffffffffffffffffffffffffffff166014610cc0565b610a918360001c6020610cc0565b604051602001610aa29291906115b9565b6040516020818303038152906040526040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610ae491906110e5565b60405180910390fd5b5050565b610afb828261071c565b610bcd57600160008084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff021916908315150217905550610b72610a4c565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45b5050565b610bdb828261071c565b15610cae57600080600084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff021916908315150217905550610c53610a4c565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16837ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b60405160405180910390a45b5050565b610cbc8282610af1565b5050565b606060006002836002610cd39190611622565b610cdd919061167c565b67ffffffffffffffff811115610cf657610cf56116d2565b5b6040519080825280601f01601f191660200182016040528015610d285781602001600182028036833780820191505090505b5090507f300000000000000000000000000000000000000000000000000000000000000081600081518110610d6057610d5f611701565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a9053507f780000000000000000000000000000000000000000000000000000000000000081600181518110610dc457610dc3611701565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a90535060006001846002610e049190611622565b610e0e919061167c565b90505b6001811115610eae577f3031323334353637383961626364656600000000000000000000000000000000600f861660108110610e5057610e4f611701565b5b1a60f81b828281518110610e6757610e66611701565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a905350600485901c945080610ea790611730565b9050610e11565b5060008414610ef2576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610ee9906117a6565b60405180910390fd5b8091505092915050565b600080fd5b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b610f3681610f01565b8114610f4157600080fd5b50565b600081359050610f5381610f2d565b92915050565b600060208284031215610f6f57610f6e610efc565b5b6000610f7d84828501610f44565b91505092915050565b60008115159050919050565b610f9b81610f86565b82525050565b6000602082019050610fb66000830184610f92565b92915050565b6000819050919050565b610fcf81610fbc565b82525050565b6000602082019050610fea6000830184610fc6565b92915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061101b82610ff0565b9050919050565b61102b81611010565b82525050565b60006020820190506110466000830184611022565b92915050565b600081519050919050565b600082825260208201905092915050565b60005b8381101561108657808201518184015260208101905061106b565b83811115611095576000848401525b50505050565b6000601f19601f8301169050919050565b60006110b78261104c565b6110c18185611057565b93506110d1818560208601611068565b6110da8161109b565b840191505092915050565b600060208201905081810360008301526110ff81846110ac565b905092915050565b61111081610fbc565b811461111b57600080fd5b50565b60008135905061112d81611107565b92915050565b60006020828403121561114957611148610efc565b5b60006111578482850161111e565b91505092915050565b61116981611010565b811461117457600080fd5b50565b60008135905061118681611160565b92915050565b600080604083850312156111a3576111a2610efc565b5b60006111b18582860161111e565b92505060206111c285828601611177565b9150509250929050565b600080604083850312156111e3576111e2610efc565b5b60006111f185828601611177565b925050602061120285828601611177565b9150509250929050565b6000819050919050565b61121f8161120c565b811461122a57600080fd5b50565b60008135905061123c81611216565b92915050565b6000806040838503121561125957611258610efc565b5b600061126785828601611177565b92505060206112788582860161122d565b9150509250929050565b60006020828403121561129857611297610efc565b5b60006112a68482850161122d565b91505092915050565b6112b88161120c565b82525050565b60006020820190506112d360008301846112af565b92915050565b7f416363657373436f6e74726f6c3a2063616e206f6e6c792072656e6f756e636560008201527f20726f6c657320666f722073656c660000000000000000000000000000000000602082015250565b6000611335602f83611057565b9150611340826112d9565b604082019050919050565b6000602082019050818103600083015261136481611328565b9050919050565b7f566f7961676572205661756c743a20464f5242494444454e0000000000000000600082015250565b60006113a1601883611057565b91506113ac8261136b565b602082019050919050565b600060208201905081810360008301526113d081611394565b9050919050565b7f5265656e7472616e637947756172643a207265656e7472616e742063616c6c00600082015250565b600061140d601f83611057565b9150611418826113d7565b602082019050919050565b6000602082019050818103600083015261143c81611400565b9050919050565b60006060820190506114586000830186611022565b6114656020830185611022565b61147260408301846112af565b949350505050565b600060408201905061148f6000830185611022565b61149c6020830184611022565b9392505050565b6000815190506114b281611216565b92915050565b6000602082840312156114ce576114cd610efc565b5b60006114dc848285016114a3565b91505092915050565b600081905092915050565b7f416363657373436f6e74726f6c3a206163636f756e7420000000000000000000600082015250565b60006115266017836114e5565b9150611531826114f0565b601782019050919050565b60006115478261104c565b61155181856114e5565b9350611561818560208601611068565b80840191505092915050565b7f206973206d697373696e6720726f6c6520000000000000000000000000000000600082015250565b60006115a36011836114e5565b91506115ae8261156d565b601182019050919050565b60006115c482611519565b91506115d0828561153c565b91506115db82611596565b91506115e7828461153c565b91508190509392505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b600061162d8261120c565b91506116388361120c565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0483118215151615611671576116706115f3565b5b828202905092915050565b60006116878261120c565b91506116928361120c565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff038211156116c7576116c66115f3565b5b828201905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b600061173b8261120c565b9150600082141561174f5761174e6115f3565b5b600182039050919050565b7f537472696e67733a20686578206c656e67746820696e73756666696369656e74600082015250565b6000611790602083611057565b915061179b8261175a565b602082019050919050565b600060208201905081810360008301526117bf81611783565b905091905056fea26469706673582212201d81b122c229b139e73fbe911d33f7563fb276ef2c1fd613f89075e4358c4c1864736f6c63430008090033608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a36001600281905550611f3a806100e36000396000f3fe6080604052600436106100915760003560e01c80639932f036116100595780639932f0361461014a578063d9caed1214610187578063e30c3978146101b0578063f2fde38b146101db578063f45b1b3a1461020457610091565b80630d8e6e2c146100965780634e71e0c8146100c15780638340f549146100d85780638da5cb5b146100f45780638f32d59b1461011f575b600080fd5b3480156100a257600080fd5b506100ab610241565b6040516100b891906113fe565b60405180910390f35b3480156100cd57600080fd5b506100d6610284565b005b6100f260048036038101906100ed91906114b9565b610420565b005b34801561010057600080fd5b50610109610791565b604051610116919061151b565b60405180910390f35b34801561012b57600080fd5b506101346107b5565b6040516101419190611551565b60405180910390f35b34801561015657600080fd5b50610171600480360381019061016c919061156c565b61080c565b60405161017e91906116b9565b60405180910390f35b34801561019357600080fd5b506101ae60048036038101906101a99190611719565b610921565b005b3480156101bc57600080fd5b506101c5610d78565b6040516101d2919061151b565b60405180910390f35b3480156101e757600080fd5b5061020260048036038101906101fd919061176c565b610d9e565b005b34801561021057600080fd5b5061022b6004803603810190610226919061156c565b610e29565b60405161023891906117a8565b60405180910390f35b606060006040518060400160405280601b81526020017f53656375726974794465706f736974457363726f7720302e302e31000000000081525090508091505090565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146102de57600080fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a3600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff166000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b600280541415610465576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161045c9061180f565b60405180910390fd5b600280819055506104746107b5565b6104b3576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016104aa9061187b565b60405180910390fd5b6104bb610eb0565b73ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff16146105625760003414610530576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105279061190d565b60405180910390fd5b61055d8230838673ffffffffffffffffffffffffffffffffffffffff16610ecc909392919063ffffffff16565b6105a5565b8034146105a4576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161059b9061199f565b60405180910390fd5b5b80600360008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825461063191906119ee565b92505081905550600060405180604001604052808381526020014264ffffffffff168152509050600460008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190806001815401808255809150506001900390600052602060002090600202016000909190919091506000820151816000015560208201518160010160006101000a81548164ffffffffff021916908364ffffffffff16021790555050508273ffffffffffffffffffffffffffffffffffffffff167f8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7858460405161077b929190611a44565b60405180910390a2506001600281905550505050565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614905090565b60606000600460008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020905080805480602002602001604051908101604052809291908181526020016000905b828210156109145783829060005260206000209060020201604051806040016040529081600082015481526020016001820160009054906101000a900464ffffffffff1664ffffffffff1664ffffffffff1681525050815260200190600101906108af565b5050505091505092915050565b6109296107b5565b610968576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161095f9061187b565b60405180910390fd5b6000600460008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020905060008080600090505b8380549050811015610b2857600560009054906101000a900464ffffffffff1664ffffffffff16848281548110610a2b57610a2a611a6d565b5b906000526020600020906002020160010160009054906101000a900464ffffffffff1642610a599190611a9c565b64ffffffffff161115610b1557838181548110610a7957610a78611a6d565b5b90600052602060002090600202016000015483610a9691906119ee565b9250838181548110610aab57610aaa611a6d565b5b906000526020600020906002020160010160009054906101000a900464ffffffffff169150838181548110610ae357610ae2611a6d565b5b90600052602060002090600202016000808201600090556001820160006101000a81549064ffffffffff021916905550505b8080610b2090611ad0565b9150506109f1565b5083821015610b6c576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b6390611b8b565b60405180910390fd5b83821115610c825760008483610b829190611bab565b9050600060405180604001604052808381526020018464ffffffffff168152509050600460008973ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190806001815401808255809150506001900390600052602060002090600202016000909190919091506000820151816000015560208201518160010160006101000a81548164ffffffffff021916908364ffffffffff160217905550505050505b83600360008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610d0e9190611bab565b92505081905550610d20868686610f55565b8473ffffffffffffffffffffffffffffffffffffffff167fd1c19fbcd4551a5edfb66d43d2e337c04837afda3482b42bdf569a8fccdae5fb8786604051610d68929190611a44565b60405180910390a2505050505050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b610da66107b5565b610de5576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610ddc9061187b565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b6000600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905092915050565b600073eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee905090565b610f4f846323b872dd60e01b858585604051602401610eed93929190611bdf565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050611072565b50505050565b610f5d610eb0565b73ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614610fbf57610fba82828573ffffffffffffffffffffffffffffffffffffffff166111399092919063ffffffff16565b61106d565b60008273ffffffffffffffffffffffffffffffffffffffff1682604051610fe590611c47565b60006040518083038185875af1925050503d8060008114611022576040519150601f19603f3d011682016040523d82523d6000602084013e611027565b606091505b505090508061106b576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161106290611ca8565b60405180910390fd5b505b505050565b60006110d4826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c65648152508573ffffffffffffffffffffffffffffffffffffffff166111bf9092919063ffffffff16565b905060008151111561113457808060200190518101906110f49190611cf4565b611133576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161112a90611d93565b60405180910390fd5b5b505050565b6111ba8363a9059cbb60e01b8484604051602401611158929190611a44565b604051602081830303815290604052907bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19166020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff8381831617835250505050611072565b505050565b60606111ce84846000856111d7565b90509392505050565b60608247101561121c576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161121390611e25565b60405180910390fd5b611225856112eb565b611264576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161125b90611e91565b60405180910390fd5b6000808673ffffffffffffffffffffffffffffffffffffffff16858760405161128d9190611eed565b60006040518083038185875af1925050503d80600081146112ca576040519150601f19603f3d011682016040523d82523d6000602084013e6112cf565b606091505b50915091506112df8282866112fe565b92505050949350505050565b600080823b905060008111915050919050565b6060831561130e5782905061135e565b6000835111156113215782518084602001fd5b816040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161135591906113fe565b60405180910390fd5b9392505050565b600081519050919050565b600082825260208201905092915050565b60005b8381101561139f578082015181840152602081019050611384565b838111156113ae576000848401525b50505050565b6000601f19601f8301169050919050565b60006113d082611365565b6113da8185611370565b93506113ea818560208601611381565b6113f3816113b4565b840191505092915050565b6000602082019050818103600083015261141881846113c5565b905092915050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061145082611425565b9050919050565b61146081611445565b811461146b57600080fd5b50565b60008135905061147d81611457565b92915050565b6000819050919050565b61149681611483565b81146114a157600080fd5b50565b6000813590506114b38161148d565b92915050565b6000806000606084860312156114d2576114d1611420565b5b60006114e08682870161146e565b93505060206114f18682870161146e565b9250506040611502868287016114a4565b9150509250925092565b61151581611445565b82525050565b6000602082019050611530600083018461150c565b92915050565b60008115159050919050565b61154b81611536565b82525050565b60006020820190506115666000830184611542565b92915050565b6000806040838503121561158357611582611420565b5b60006115918582860161146e565b92505060206115a28582860161146e565b9150509250929050565b600081519050919050565b600082825260208201905092915050565b6000819050602082019050919050565b6115e181611483565b82525050565b600064ffffffffff82169050919050565b611601816115e7565b82525050565b60408201600082015161161d60008501826115d8565b50602082015161163060208501826115f8565b50505050565b60006116428383611607565b60408301905092915050565b6000602082019050919050565b6000611666826115ac565b61167081856115b7565b935061167b836115c8565b8060005b838110156116ac5781516116938882611636565b975061169e8361164e565b92505060018101905061167f565b5085935050505092915050565b600060208201905081810360008301526116d3818461165b565b905092915050565b60006116e682611425565b9050919050565b6116f6816116db565b811461170157600080fd5b50565b600081359050611713816116ed565b92915050565b60008060006060848603121561173257611731611420565b5b60006117408682870161146e565b935050602061175186828701611704565b9250506040611762868287016114a4565b9150509250925092565b60006020828403121561178257611781611420565b5b60006117908482850161146e565b91505092915050565b6117a281611483565b82525050565b60006020820190506117bd6000830184611799565b92915050565b7f5265656e7472616e637947756172643a207265656e7472616e742063616c6c00600082015250565b60006117f9601f83611370565b9150611804826117c3565b602082019050919050565b60006020820190508181036000830152611828816117ec565b9050919050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b6000611865602083611370565b91506118708261182f565b602082019050919050565b6000602082019050818103600083015261189481611858565b9050919050565b7f557365722069732073656e64696e672045544820616c6f6e672077697468207460008201527f6865204552433230207472616e736665722e0000000000000000000000000000602082015250565b60006118f7603283611370565b91506119028261189b565b604082019050919050565b60006020820190508181036000830152611926816118ea565b9050919050565b7f54686520616d6f756e7420616e64207468652076616c75652073656e7420746f60008201527f206465706f73697420646f206e6f74206d617463680000000000000000000000602082015250565b6000611989603583611370565b91506119948261192d565b604082019050919050565b600060208201905081810360008301526119b88161197c565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60006119f982611483565b9150611a0483611483565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03821115611a3957611a386119bf565b5b828201905092915050565b6000604082019050611a59600083018561150c565b611a666020830184611799565b9392505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b6000611aa7826115e7565b9150611ab2836115e7565b925082821015611ac557611ac46119bf565b5b828203905092915050565b6000611adb82611483565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff821415611b0e57611b0d6119bf565b5b600182019050919050565b7f446f206e6f74206861766520656e6f75676820616d6f756e7420746f2077697460008201527f6864726177000000000000000000000000000000000000000000000000000000602082015250565b6000611b75602583611370565b9150611b8082611b19565b604082019050919050565b60006020820190508181036000830152611ba481611b68565b9050919050565b6000611bb682611483565b9150611bc183611483565b925082821015611bd457611bd36119bf565b5b828203905092915050565b6000606082019050611bf4600083018661150c565b611c01602083018561150c565b611c0e6040830184611799565b949350505050565b600081905092915050565b50565b6000611c31600083611c16565b9150611c3c82611c21565b600082019050919050565b6000611c5282611c24565b9150819050919050565b7f5472616e73666572206f6620455448206661696c656400000000000000000000600082015250565b6000611c92601683611370565b9150611c9d82611c5c565b602082019050919050565b60006020820190508181036000830152611cc181611c85565b9050919050565b611cd181611536565b8114611cdc57600080fd5b50565b600081519050611cee81611cc8565b92915050565b600060208284031215611d0a57611d09611420565b5b6000611d1884828501611cdf565b91505092915050565b7f5361666545524332303a204552433230206f7065726174696f6e20646964206e60008201527f6f74207375636365656400000000000000000000000000000000000000000000602082015250565b6000611d7d602a83611370565b9150611d8882611d21565b604082019050919050565b60006020820190508181036000830152611dac81611d70565b9050919050565b7f416464726573733a20696e73756666696369656e742062616c616e636520666f60008201527f722063616c6c0000000000000000000000000000000000000000000000000000602082015250565b6000611e0f602683611370565b9150611e1a82611db3565b604082019050919050565b60006020820190508181036000830152611e3e81611e02565b9050919050565b7f416464726573733a2063616c6c20746f206e6f6e2d636f6e7472616374000000600082015250565b6000611e7b601d83611370565b9150611e8682611e45565b602082019050919050565b60006020820190508181036000830152611eaa81611e6e565b9050919050565b600081519050919050565b6000611ec782611eb1565b611ed18185611c16565b9350611ee1818560208601611381565b80840191505092915050565b6000611ef98284611ebc565b91508190509291505056fea2646970667358221220a8380646014b0adc1746e0deaf8295ed20ef81e56c4524b2a4f53c24cbdf28c264736f6c63430008090033";

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

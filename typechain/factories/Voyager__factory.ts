/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Voyager, VoyagerInterface } from "../Voyager";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_operator",
        type: "address",
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
    name: "OPERATOR",
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
    name: "createVault",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "getAddressResolverAddress",
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
    name: "getLiquidityManagerName",
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
    name: "getLoanManagerName",
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
    name: "getVault",
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
    name: "getVaultManagerAddress",
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
    name: "getVaultManagerName",
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
    name: "getVaultStorageName",
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
    inputs: [],
    name: "liquidityManagerName",
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
    name: "loanManagerName",
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
    ],
    name: "removeMaxSecurityDeposit",
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
        internalType: "address",
        name: "_addressResolver",
        type: "address",
      },
    ],
    name: "setAddressResolverAddress",
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
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "setMaxSecurityDeposit",
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
  {
    inputs: [],
    name: "vaultManagerName",
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
    name: "vaultStorageName",
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
];

const _bytecode =
  "0x60806040523480156200001157600080fd5b5060405162001add38038062001add833981810160405281019062000037919062000253565b620000697f523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c826200007060201b60201c565b5062000285565b6200008282826200008660201b60201c565b5050565b6200009882826200017760201b60201c565b6200017357600160008084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff02191690831515021790555062000118620001e160201b60201c565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45b5050565b600080600084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16905092915050565b600033905090565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006200021b82620001ee565b9050919050565b6200022d816200020e565b81146200023957600080fd5b50565b6000815190506200024d8162000222565b92915050565b6000602082840312156200026c576200026b620001e9565b5b60006200027c848285016200023c565b91505092915050565b61184880620002956000396000f3fe608060405234801561001057600080fd5b50600436106101585760003560e01c80638c942ffd116100c35780639f423c3a1161007c5780639f423c3a146103a7578063a217fddf146103c5578063ad64caed146103e3578063b550906f14610401578063b75fc04a1461041f578063d547741f1461043b57610158565b80638c942ffd146102e15780638d928af8146102ff57806391d148541461031d57806394f674431461034d578063983d27371461036b5780639894c89e1461038957610158565b8063283761a411610115578063283761a4146102335780632f2ff15d1461025157806336568abe1461026d57806353b83e92146102895780635d12928b146102a55780636023f816146102c357610158565b806301ffc9a71461015d57806305a2ee2a1461018d57806306a8978c146101ab57806307bc4388146101c957806319c1e7fc146101e7578063248a9ca314610203575b600080fd5b6101776004803603810190610172919061110f565b610457565b6040516101849190611157565b60405180910390f35b6101956104d1565b6040516101a291906111b3565b60405180910390f35b6101b36104f7565b6040516101c091906111e7565b60405180910390f35b6101d161051f565b6040516101de91906111b3565b60405180910390f35b61020160048036038101906101fc919061122e565b6105f1565b005b61021d60048036038101906102189190611287565b610699565b60405161022a91906111e7565b60405180910390f35b61023b6106b8565b60405161024891906111e7565b60405180910390f35b61026b600480360381019061026691906112b4565b6106e0565b005b610287600480360381019061028291906112b4565b610709565b005b6102a3600480360381019061029e919061132a565b61078c565b005b6102ad610837565b6040516102ba91906111b3565b60405180910390f35b6102cb6108d0565b6040516102d891906111e7565b60405180910390f35b6102e96108f4565b6040516102f691906111e7565b60405180910390f35b610307610918565b60405161031491906111b3565b60405180910390f35b610337600480360381019061033291906112b4565b6109af565b6040516103449190611157565b60405180910390f35b610355610a19565b60405161036291906111b3565b60405180910390f35b610373610a43565b60405161038091906111e7565b60405180910390f35b610391610a67565b60405161039e91906111e7565b60405180910390f35b6103af610a8b565b6040516103bc91906111e7565b60405180910390f35b6103cd610ab3565b6040516103da91906111e7565b60405180910390f35b6103eb610aba565b6040516103f891906111e7565b60405180910390f35b610409610ade565b60405161041691906111e7565b60405180910390f35b6104396004803603810190610434919061122e565b610b06565b005b610455600480360381019061045091906112b4565b610b7d565b005b60007f7965db0b000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff191614806104ca57506104c982610ba6565b5b9050919050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60007f6c69717569646974794d616e6167657200000000000000000000000000000000905090565b6000600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166321f8a7217f7661756c744d616e6167657200000000000000000000000000000000000000006040518263ffffffff1660e01b815260040161059c91906111e7565b60206040518083038186803b1580156105b457600080fd5b505afa1580156105c8573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906105ec919061137f565b905090565b7f523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c6106238161061e610c10565b610c18565b61062b61051f565b73ffffffffffffffffffffffffffffffffffffffff166319c1e7fc836040518263ffffffff1660e01b815260040161066391906111b3565b600060405180830381600087803b15801561067d57600080fd5b505af1158015610691573d6000803e3d6000fd5b505050505050565b6000806000838152602001908152602001600020600101549050919050565b60007f7661756c7453746f726167650000000000000000000000000000000000000000905090565b6106e982610699565b6106fa816106f5610c10565b610c18565b6107048383610cb5565b505050565b610711610c10565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff161461077e576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016107759061142f565b60405180910390fd5b6107888282610d95565b5050565b7f523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c6107be816107b9610c10565b610c18565b6107c661051f565b73ffffffffffffffffffffffffffffffffffffffff166353b83e9284846040518363ffffffff1660e01b815260040161080092919061145e565b600060405180830381600087803b15801561081a57600080fd5b505af115801561082e573d6000803e3d6000fd5b50505050505050565b600061084161051f565b73ffffffffffffffffffffffffffffffffffffffff1663b4bd6f46336040518263ffffffff1660e01b815260040161087991906111b3565b602060405180830381600087803b15801561089357600080fd5b505af11580156108a7573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906108cb919061137f565b905090565b7f6c69717569646974794d616e616765720000000000000000000000000000000081565b7f7661756c7453746f72616765000000000000000000000000000000000000000081565b600061092261051f565b73ffffffffffffffffffffffffffffffffffffffff16630eb9af38336040518263ffffffff1660e01b815260040161095a91906111b3565b60206040518083038186803b15801561097257600080fd5b505afa158015610986573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906109aa919061137f565b905090565b600080600084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16905092915050565b6000600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b7f523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c81565b7f7661756c744d616e61676572000000000000000000000000000000000000000081565b60007f7661756c744d616e616765720000000000000000000000000000000000000000905090565b6000801b81565b7f6c6f616e4d616e6167657200000000000000000000000000000000000000000081565b60007f6c6f616e4d616e61676572000000000000000000000000000000000000000000905090565b7f523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c610b3881610b33610c10565b610c18565b81600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505050565b610b8682610699565b610b9781610b92610c10565b610c18565b610ba18383610d95565b505050565b60007f01ffc9a7000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916149050919050565b600033905090565b610c2282826109af565b610cb157610c478173ffffffffffffffffffffffffffffffffffffffff166014610e76565b610c558360001c6020610e76565b604051602001610c66929190611599565b6040516020818303038152906040526040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610ca8919061161d565b60405180910390fd5b5050565b610cbf82826109af565b610d9157600160008084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff021916908315150217905550610d36610c10565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45b5050565b610d9f82826109af565b15610e7257600080600084815260200190815260200160002060000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff021916908315150217905550610e17610c10565b73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16837ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b60405160405180910390a45b5050565b606060006002836002610e89919061166e565b610e9391906116c8565b67ffffffffffffffff811115610eac57610eab61171e565b5b6040519080825280601f01601f191660200182016040528015610ede5781602001600182028036833780820191505090505b5090507f300000000000000000000000000000000000000000000000000000000000000081600081518110610f1657610f1561174d565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a9053507f780000000000000000000000000000000000000000000000000000000000000081600181518110610f7a57610f7961174d565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a90535060006001846002610fba919061166e565b610fc491906116c8565b90505b6001811115611064577f3031323334353637383961626364656600000000000000000000000000000000600f8616601081106110065761100561174d565b5b1a60f81b82828151811061101d5761101c61174d565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a905350600485901c94508061105d9061177c565b9050610fc7565b50600084146110a8576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161109f906117f2565b60405180910390fd5b8091505092915050565b600080fd5b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b6110ec816110b7565b81146110f757600080fd5b50565b600081359050611109816110e3565b92915050565b600060208284031215611125576111246110b2565b5b6000611133848285016110fa565b91505092915050565b60008115159050919050565b6111518161113c565b82525050565b600060208201905061116c6000830184611148565b92915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061119d82611172565b9050919050565b6111ad81611192565b82525050565b60006020820190506111c860008301846111a4565b92915050565b6000819050919050565b6111e1816111ce565b82525050565b60006020820190506111fc60008301846111d8565b92915050565b61120b81611192565b811461121657600080fd5b50565b60008135905061122881611202565b92915050565b600060208284031215611244576112436110b2565b5b600061125284828501611219565b91505092915050565b611264816111ce565b811461126f57600080fd5b50565b6000813590506112818161125b565b92915050565b60006020828403121561129d5761129c6110b2565b5b60006112ab84828501611272565b91505092915050565b600080604083850312156112cb576112ca6110b2565b5b60006112d985828601611272565b92505060206112ea85828601611219565b9150509250929050565b6000819050919050565b611307816112f4565b811461131257600080fd5b50565b600081359050611324816112fe565b92915050565b60008060408385031215611341576113406110b2565b5b600061134f85828601611219565b925050602061136085828601611315565b9150509250929050565b60008151905061137981611202565b92915050565b600060208284031215611395576113946110b2565b5b60006113a38482850161136a565b91505092915050565b600082825260208201905092915050565b7f416363657373436f6e74726f6c3a2063616e206f6e6c792072656e6f756e636560008201527f20726f6c657320666f722073656c660000000000000000000000000000000000602082015250565b6000611419602f836113ac565b9150611424826113bd565b604082019050919050565b600060208201905081810360008301526114488161140c565b9050919050565b611458816112f4565b82525050565b600060408201905061147360008301856111a4565b611480602083018461144f565b9392505050565b600081905092915050565b7f416363657373436f6e74726f6c3a206163636f756e7420000000000000000000600082015250565b60006114c8601783611487565b91506114d382611492565b601782019050919050565b600081519050919050565b60005b838110156115075780820151818401526020810190506114ec565b83811115611516576000848401525b50505050565b6000611527826114de565b6115318185611487565b93506115418185602086016114e9565b80840191505092915050565b7f206973206d697373696e6720726f6c6520000000000000000000000000000000600082015250565b6000611583601183611487565b915061158e8261154d565b601182019050919050565b60006115a4826114bb565b91506115b0828561151c565b91506115bb82611576565b91506115c7828461151c565b91508190509392505050565b6000601f19601f8301169050919050565b60006115ef826114de565b6115f981856113ac565b93506116098185602086016114e9565b611612816115d3565b840191505092915050565b6000602082019050818103600083015261163781846115e4565b905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000611679826112f4565b9150611684836112f4565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff04831182151516156116bd576116bc61163f565b5b828202905092915050565b60006116d3826112f4565b91506116de836112f4565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff038211156117135761171261163f565b5b828201905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b6000611787826112f4565b9150600082141561179b5761179a61163f565b5b600182039050919050565b7f537472696e67733a20686578206c656e67746820696e73756666696369656e74600082015250565b60006117dc6020836113ac565b91506117e7826117a6565b602082019050919050565b6000602082019050818103600083015261180b816117cf565b905091905056fea264697066735822122061a0ea8476740e3c1886b9d6222af70f16ed5754ab631d41a0878a31ef9f351664736f6c63430008090033";

export class Voyager__factory extends ContractFactory {
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
    _operator: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<Voyager> {
    return super.deploy(_operator, overrides || {}) as Promise<Voyager>;
  }
  getDeployTransaction(
    _operator: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(_operator, overrides || {});
  }
  attach(address: string): Voyager {
    return super.attach(address) as Voyager;
  }
  connect(signer: Signer): Voyager__factory {
    return super.connect(signer) as Voyager__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): VoyagerInterface {
    return new utils.Interface(_abi) as VoyagerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): Voyager {
    return new Contract(address, _abi, signerOrProvider) as Voyager;
  }
}

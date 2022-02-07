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
import type {
  DefaultReserveInterestRateStrategy,
  DefaultReserveInterestRateStrategyInterface,
} from "../DefaultReserveInterestRateStrategy";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_reserve",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_baseVariableBorrowRate",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_variableRateSlope1",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_variableRateSlope2",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_stableRateSlope1",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_stableRateSlope2",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "EXCESS_UTILIZATION_RATE",
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
    name: "OPTIMAL_UTILIZATION_RATE",
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
    name: "baseVariableBorrowRate",
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
        internalType: "uint256",
        name: "_utilizationRate",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_totalBorrows",
        type: "uint256",
      },
    ],
    name: "calculateInterestRates",
    outputs: [
      {
        internalType: "uint256",
        name: "liquidityRate",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getBaseVariableBorrowRate",
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
    name: "getStableRateSlope1",
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
    name: "getStableRateSlope2",
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
    name: "getVariableRateSlope1",
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
    name: "getVariableRateSlope2",
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
    name: "reserve",
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
    name: "stableRateSlope1",
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
    name: "stableRateSlope2",
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
    name: "variableRateSlope1",
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
    name: "variableRateSlope2",
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
];

const _bytecode =
  "0x608060405234801561001057600080fd5b5060405161068e38038061068e8339818101604052810190610032919061013a565b846000819055508360018190555082600281905550816003819055508060048190555085600560006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505050505050506101c7565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006100d1826100a6565b9050919050565b6100e1816100c6565b81146100ec57600080fd5b50565b6000815190506100fe816100d8565b92915050565b6000819050919050565b61011781610104565b811461012257600080fd5b50565b6000815190506101348161010e565b92915050565b60008060008060008060c08789031215610157576101566100a1565b5b600061016589828a016100ef565b965050602061017689828a01610125565b955050604061018789828a01610125565b945050606061019889828a01610125565b93505060806101a989828a01610125565b92505060a06101ba89828a01610125565b9150509295509295509295565b6104b8806101d66000396000f3fe608060405234801561001057600080fd5b50600436106100ea5760003560e01c80637b832f581161008c578063ccab01a311610066578063ccab01a31461022d578063cd3293de1461024b578063d5cd739114610269578063f420240914610287576100ea565b80637b832f58146101d3578063a15f30ac146101f1578063b25895441461020f576100ea565b806314e32da4116100c857806314e32da41461015b578063173198731461017957806334762ca51461019757806365614f81146101b5576100ea565b80630ac35529146100ef5780630b3429a21461011f5780630bdf953f1461013d575b600080fd5b610109600480360381019061010491906103db565b6102a5565b604051610116919061043d565b60405180910390f35b6101276102ae565b604051610134919061043d565b60405180910390f35b6101456102b8565b604051610152919061043d565b60405180910390f35b6101636102be565b604051610170919061043d565b60405180910390f35b6101816102c8565b60405161018e919061043d565b60405180910390f35b61019f6102d7565b6040516101ac919061043d565b60405180910390f35b6101bd6102e0565b6040516101ca919061043d565b60405180910390f35b6101db6102e6565b6040516101e8919061043d565b60405180910390f35b6101f96102ec565b604051610206919061043d565b60405180910390f35b6102176102fc565b604051610224919061043d565b60405180910390f35b610235610302565b604051610242919061043d565b60405180910390f35b610253610308565b6040516102609190610467565b60405180910390f35b61027161032e565b60405161027e919061043d565b60405180910390f35b61028f610338565b60405161029c919061043d565b60405180910390f35b60009392505050565b6000600154905090565b60035481565b6000600454905090565b6aa56fa5b99019a5c800000081565b60008054905090565b60025481565b60015481565b6b0295be96e64066972000000081565b60005481565b60045481565b600560009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6000600354905090565b6000600254905090565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061037282610347565b9050919050565b61038281610367565b811461038d57600080fd5b50565b60008135905061039f81610379565b92915050565b6000819050919050565b6103b8816103a5565b81146103c357600080fd5b50565b6000813590506103d5816103af565b92915050565b6000806000606084860312156103f4576103f3610342565b5b600061040286828701610390565b9350506020610413868287016103c6565b9250506040610424868287016103c6565b9150509250925092565b610437816103a5565b82525050565b6000602082019050610452600083018461042e565b92915050565b61046181610367565b82525050565b600060208201905061047c6000830184610458565b9291505056fea2646970667358221220aeac0acc759dc191a3a4f623abf4837bc2104b0d403ae0224bbb47472aebce1a64736f6c63430008090033";

export class DefaultReserveInterestRateStrategy__factory extends ContractFactory {
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
    _reserve: string,
    _baseVariableBorrowRate: BigNumberish,
    _variableRateSlope1: BigNumberish,
    _variableRateSlope2: BigNumberish,
    _stableRateSlope1: BigNumberish,
    _stableRateSlope2: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<DefaultReserveInterestRateStrategy> {
    return super.deploy(
      _reserve,
      _baseVariableBorrowRate,
      _variableRateSlope1,
      _variableRateSlope2,
      _stableRateSlope1,
      _stableRateSlope2,
      overrides || {}
    ) as Promise<DefaultReserveInterestRateStrategy>;
  }
  getDeployTransaction(
    _reserve: string,
    _baseVariableBorrowRate: BigNumberish,
    _variableRateSlope1: BigNumberish,
    _variableRateSlope2: BigNumberish,
    _stableRateSlope1: BigNumberish,
    _stableRateSlope2: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _reserve,
      _baseVariableBorrowRate,
      _variableRateSlope1,
      _variableRateSlope2,
      _stableRateSlope1,
      _stableRateSlope2,
      overrides || {}
    );
  }
  attach(address: string): DefaultReserveInterestRateStrategy {
    return super.attach(address) as DefaultReserveInterestRateStrategy;
  }
  connect(signer: Signer): DefaultReserveInterestRateStrategy__factory {
    return super.connect(signer) as DefaultReserveInterestRateStrategy__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): DefaultReserveInterestRateStrategyInterface {
    return new utils.Interface(
      _abi
    ) as DefaultReserveInterestRateStrategyInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): DefaultReserveInterestRateStrategy {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as DefaultReserveInterestRateStrategy;
  }
}

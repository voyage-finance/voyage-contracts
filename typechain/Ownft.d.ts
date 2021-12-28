/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import {
  ethers,
  EventFilter,
  Signer,
  BigNumber,
  BigNumberish,
  PopulatedTransaction,
  BaseContract,
  ContractTransaction,
  Overrides,
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";

interface OwnftInterface extends ethers.utils.Interface {
  functions: {
    "claimOwnership()": FunctionFragment;
    "deposit(address,uint256)": FunctionFragment;
    "isOwner()": FunctionFragment;
    "owner()": FunctionFragment;
    "pendingOwner()": FunctionFragment;
    "setDepositWhiteList(address,bool)": FunctionFragment;
    "setInterestRate(uint256)": FunctionFragment;
    "transferOwnership(address)": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "claimOwnership",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "deposit",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "isOwner", values?: undefined): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "pendingOwner",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "setDepositWhiteList",
    values: [string, boolean]
  ): string;
  encodeFunctionData(
    functionFragment: "setInterestRate",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [string]
  ): string;

  decodeFunctionResult(
    functionFragment: "claimOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "deposit", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "isOwner", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "pendingOwner",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setDepositWhiteList",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setInterestRate",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;

  events: {
    "Deposit(address,address,uint256,uint256)": EventFragment;
    "InterestRateSet(uint256,address)": EventFragment;
    "OwnershipTransferred(address,address)": EventFragment;
    "WhilteListToken(address,bool,address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "Deposit"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "InterestRateSet"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "WhilteListToken"): EventFragment;
}

export type DepositEvent = TypedEvent<
  [string, string, BigNumber, BigNumber] & {
    _token: string;
    _user: string;
    _amount: BigNumber;
    _timestamp: BigNumber;
  }
>;

export type InterestRateSetEvent = TypedEvent<
  [BigNumber, string] & { _interest_rate: BigNumber; _operator: string }
>;

export type OwnershipTransferredEvent = TypedEvent<
  [string, string] & { previousOwner: string; newOwner: string }
>;

export type WhilteListTokenEvent = TypedEvent<
  [string, boolean, string] & {
    _token: string;
    _enable: boolean;
    _operator: string;
  }
>;

export class Ownft extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  listeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter?: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): Array<TypedListener<EventArgsArray, EventArgsObject>>;
  off<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  on<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  once<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeListener<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeAllListeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): this;

  listeners(eventName?: string): Array<Listener>;
  off(eventName: string, listener: Listener): this;
  on(eventName: string, listener: Listener): this;
  once(eventName: string, listener: Listener): this;
  removeListener(eventName: string, listener: Listener): this;
  removeAllListeners(eventName?: string): this;

  queryFilter<EventArgsArray extends Array<any>, EventArgsObject>(
    event: TypedEventFilter<EventArgsArray, EventArgsObject>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEvent<EventArgsArray & EventArgsObject>>>;

  interface: OwnftInterface;

  functions: {
    claimOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    deposit(
      token: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    isOwner(overrides?: CallOverrides): Promise<[boolean]>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    pendingOwner(overrides?: CallOverrides): Promise<[string]>;

    setDepositWhiteList(
      token: string,
      enable: boolean,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    setInterestRate(
      interest_rate: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;
  };

  claimOwnership(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  deposit(
    token: string,
    amount: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  isOwner(overrides?: CallOverrides): Promise<boolean>;

  owner(overrides?: CallOverrides): Promise<string>;

  pendingOwner(overrides?: CallOverrides): Promise<string>;

  setDepositWhiteList(
    token: string,
    enable: boolean,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  setInterestRate(
    interest_rate: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  transferOwnership(
    newOwner: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    claimOwnership(overrides?: CallOverrides): Promise<void>;

    deposit(
      token: string,
      amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    isOwner(overrides?: CallOverrides): Promise<boolean>;

    owner(overrides?: CallOverrides): Promise<string>;

    pendingOwner(overrides?: CallOverrides): Promise<string>;

    setDepositWhiteList(
      token: string,
      enable: boolean,
      overrides?: CallOverrides
    ): Promise<void>;

    setInterestRate(
      interest_rate: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    transferOwnership(
      newOwner: string,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "Deposit(address,address,uint256,uint256)"(
      _token?: null,
      _user?: null,
      _amount?: null,
      _timestamp?: null
    ): TypedEventFilter<
      [string, string, BigNumber, BigNumber],
      {
        _token: string;
        _user: string;
        _amount: BigNumber;
        _timestamp: BigNumber;
      }
    >;

    Deposit(
      _token?: null,
      _user?: null,
      _amount?: null,
      _timestamp?: null
    ): TypedEventFilter<
      [string, string, BigNumber, BigNumber],
      {
        _token: string;
        _user: string;
        _amount: BigNumber;
        _timestamp: BigNumber;
      }
    >;

    "InterestRateSet(uint256,address)"(
      _interest_rate?: null,
      _operator?: null
    ): TypedEventFilter<
      [BigNumber, string],
      { _interest_rate: BigNumber; _operator: string }
    >;

    InterestRateSet(
      _interest_rate?: null,
      _operator?: null
    ): TypedEventFilter<
      [BigNumber, string],
      { _interest_rate: BigNumber; _operator: string }
    >;

    "OwnershipTransferred(address,address)"(
      previousOwner?: string | null,
      newOwner?: string | null
    ): TypedEventFilter<
      [string, string],
      { previousOwner: string; newOwner: string }
    >;

    OwnershipTransferred(
      previousOwner?: string | null,
      newOwner?: string | null
    ): TypedEventFilter<
      [string, string],
      { previousOwner: string; newOwner: string }
    >;

    "WhilteListToken(address,bool,address)"(
      _token?: null,
      _enable?: null,
      _operator?: null
    ): TypedEventFilter<
      [string, boolean, string],
      { _token: string; _enable: boolean; _operator: string }
    >;

    WhilteListToken(
      _token?: null,
      _enable?: null,
      _operator?: null
    ): TypedEventFilter<
      [string, boolean, string],
      { _token: string; _enable: boolean; _operator: string }
    >;
  };

  estimateGas: {
    claimOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    deposit(
      token: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    isOwner(overrides?: CallOverrides): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    pendingOwner(overrides?: CallOverrides): Promise<BigNumber>;

    setDepositWhiteList(
      token: string,
      enable: boolean,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    setInterestRate(
      interest_rate: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    claimOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    deposit(
      token: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    isOwner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    pendingOwner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    setDepositWhiteList(
      token: string,
      enable: boolean,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    setInterestRate(
      interest_rate: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;
  };
}

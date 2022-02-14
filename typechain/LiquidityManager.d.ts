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
  PayableOverrides,
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";

interface LiquidityManagerInterface extends ethers.utils.Interface {
  functions: {
    "activateReserve(address)": FunctionFragment;
    "claimOwnership()": FunctionFragment;
    "deactivateReserve(address)": FunctionFragment;
    "depositLiquidity(address,uint8,uint256)": FunctionFragment;
    "getReserveAvailableLiquidity(address)": FunctionFragment;
    "getReserveJDTokenAddress(address)": FunctionFragment;
    "getReserveNormalizedIncome(address,uint8)": FunctionFragment;
    "getReserveSDTokenAddress(address)": FunctionFragment;
    "getReserveTotalLiquidity(address)": FunctionFragment;
    "initReserve(address,uint8,address)": FunctionFragment;
    "initReserveWithData(address,string,string,string,string,uint8,address)": FunctionFragment;
    "isOwner()": FunctionFragment;
    "owner()": FunctionFragment;
    "pendingOwner()": FunctionFragment;
    "redeemUnderlying(address,uint8,address,uint256,uint256)": FunctionFragment;
    "transferOwnership(address)": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "activateReserve",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "claimOwnership",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "deactivateReserve",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "depositLiquidity",
    values: [string, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getReserveAvailableLiquidity",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "getReserveJDTokenAddress",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "getReserveNormalizedIncome",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getReserveSDTokenAddress",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "getReserveTotalLiquidity",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "initReserve",
    values: [string, BigNumberish, string]
  ): string;
  encodeFunctionData(
    functionFragment: "initReserveWithData",
    values: [string, string, string, string, string, BigNumberish, string]
  ): string;
  encodeFunctionData(functionFragment: "isOwner", values?: undefined): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "pendingOwner",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "redeemUnderlying",
    values: [string, BigNumberish, string, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [string]
  ): string;

  decodeFunctionResult(
    functionFragment: "activateReserve",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "claimOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "deactivateReserve",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "depositLiquidity",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getReserveAvailableLiquidity",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getReserveJDTokenAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getReserveNormalizedIncome",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getReserveSDTokenAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getReserveTotalLiquidity",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "initReserve",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "initReserveWithData",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "isOwner", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "pendingOwner",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "redeemUnderlying",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;

  events: {
    "Deposit(address,address,uint256,uint256)": EventFragment;
    "OwnershipTransferred(address,address)": EventFragment;
    "RedeemUnderlying(address,address,uint256,uint256)": EventFragment;
    "ReserveActivated(address)": EventFragment;
    "ReserveDeactivated(address)": EventFragment;
    "ReserveInitialized(address,address,address,address)": EventFragment;
    "ReserveUpdated(address,uint256,uint256,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "Deposit"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RedeemUnderlying"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ReserveActivated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ReserveDeactivated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ReserveInitialized"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ReserveUpdated"): EventFragment;
}

export type DepositEvent = TypedEvent<
  [string, string, BigNumber, BigNumber] & {
    _reserve: string;
    _user: string;
    _amount: BigNumber;
    _timestamp: BigNumber;
  }
>;

export type OwnershipTransferredEvent = TypedEvent<
  [string, string] & { previousOwner: string; newOwner: string }
>;

export type RedeemUnderlyingEvent = TypedEvent<
  [string, string, BigNumber, BigNumber] & {
    _reserve: string;
    _user: string;
    _amount: BigNumber;
    _timestamp: BigNumber;
  }
>;

export type ReserveActivatedEvent = TypedEvent<[string] & { _reserve: string }>;

export type ReserveDeactivatedEvent = TypedEvent<
  [string] & { _reserve: string }
>;

export type ReserveInitializedEvent = TypedEvent<
  [string, string, string, string] & {
    _reserve: string;
    _jdToken: string;
    _sdToken: string;
    _interestRateStrategyAddress: string;
  }
>;

export type ReserveUpdatedEvent = TypedEvent<
  [string, BigNumber, BigNumber, BigNumber] & {
    reserve: string;
    liquidityRate: BigNumber;
    currentJuniorLiquidityIndex: BigNumber;
    currentSeniorLiquidityIndex: BigNumber;
  }
>;

export class LiquidityManager extends BaseContract {
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

  interface: LiquidityManagerInterface;

  functions: {
    activateReserve(
      _reserve: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    claimOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    deactivateReserve(
      _reserve: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    depositLiquidity(
      _reserve: string,
      _tranche: BigNumberish,
      _amount: BigNumberish,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    getReserveAvailableLiquidity(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    getReserveJDTokenAddress(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<[string]>;

    getReserveNormalizedIncome(
      _reserve: string,
      _tranche: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    getReserveSDTokenAddress(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<[string]>;

    getReserveTotalLiquidity(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    initReserve(
      _reserve: string,
      _underlyingAssetDecimals: BigNumberish,
      _interestRateStrategyAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    initReserveWithData(
      _reserve: string,
      _jdTokenName: string,
      _jdTokenSymbol: string,
      _sdTokenName: string,
      _sdTokenSymbol: string,
      _underlyingAssetDecimals: BigNumberish,
      _interestRateStrategyAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    isOwner(overrides?: CallOverrides): Promise<[boolean]>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    pendingOwner(overrides?: CallOverrides): Promise<[string]>;

    redeemUnderlying(
      _reserve: string,
      _tranche: BigNumberish,
      _user: string,
      _amount: BigNumberish,
      _aTokenBalanceAfterRedeem: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;
  };

  activateReserve(
    _reserve: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  claimOwnership(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  deactivateReserve(
    _reserve: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  depositLiquidity(
    _reserve: string,
    _tranche: BigNumberish,
    _amount: BigNumberish,
    overrides?: PayableOverrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  getReserveAvailableLiquidity(
    _reserve: string,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  getReserveJDTokenAddress(
    _reserve: string,
    overrides?: CallOverrides
  ): Promise<string>;

  getReserveNormalizedIncome(
    _reserve: string,
    _tranche: BigNumberish,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  getReserveSDTokenAddress(
    _reserve: string,
    overrides?: CallOverrides
  ): Promise<string>;

  getReserveTotalLiquidity(
    _reserve: string,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  initReserve(
    _reserve: string,
    _underlyingAssetDecimals: BigNumberish,
    _interestRateStrategyAddress: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  initReserveWithData(
    _reserve: string,
    _jdTokenName: string,
    _jdTokenSymbol: string,
    _sdTokenName: string,
    _sdTokenSymbol: string,
    _underlyingAssetDecimals: BigNumberish,
    _interestRateStrategyAddress: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  isOwner(overrides?: CallOverrides): Promise<boolean>;

  owner(overrides?: CallOverrides): Promise<string>;

  pendingOwner(overrides?: CallOverrides): Promise<string>;

  redeemUnderlying(
    _reserve: string,
    _tranche: BigNumberish,
    _user: string,
    _amount: BigNumberish,
    _aTokenBalanceAfterRedeem: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  transferOwnership(
    newOwner: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    activateReserve(_reserve: string, overrides?: CallOverrides): Promise<void>;

    claimOwnership(overrides?: CallOverrides): Promise<void>;

    deactivateReserve(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<void>;

    depositLiquidity(
      _reserve: string,
      _tranche: BigNumberish,
      _amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    getReserveAvailableLiquidity(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getReserveJDTokenAddress(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<string>;

    getReserveNormalizedIncome(
      _reserve: string,
      _tranche: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getReserveSDTokenAddress(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<string>;

    getReserveTotalLiquidity(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    initReserve(
      _reserve: string,
      _underlyingAssetDecimals: BigNumberish,
      _interestRateStrategyAddress: string,
      overrides?: CallOverrides
    ): Promise<void>;

    initReserveWithData(
      _reserve: string,
      _jdTokenName: string,
      _jdTokenSymbol: string,
      _sdTokenName: string,
      _sdTokenSymbol: string,
      _underlyingAssetDecimals: BigNumberish,
      _interestRateStrategyAddress: string,
      overrides?: CallOverrides
    ): Promise<void>;

    isOwner(overrides?: CallOverrides): Promise<boolean>;

    owner(overrides?: CallOverrides): Promise<string>;

    pendingOwner(overrides?: CallOverrides): Promise<string>;

    redeemUnderlying(
      _reserve: string,
      _tranche: BigNumberish,
      _user: string,
      _amount: BigNumberish,
      _aTokenBalanceAfterRedeem: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    transferOwnership(
      newOwner: string,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "Deposit(address,address,uint256,uint256)"(
      _reserve?: string | null,
      _user?: string | null,
      _amount?: null,
      _timestamp?: null
    ): TypedEventFilter<
      [string, string, BigNumber, BigNumber],
      {
        _reserve: string;
        _user: string;
        _amount: BigNumber;
        _timestamp: BigNumber;
      }
    >;

    Deposit(
      _reserve?: string | null,
      _user?: string | null,
      _amount?: null,
      _timestamp?: null
    ): TypedEventFilter<
      [string, string, BigNumber, BigNumber],
      {
        _reserve: string;
        _user: string;
        _amount: BigNumber;
        _timestamp: BigNumber;
      }
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

    "RedeemUnderlying(address,address,uint256,uint256)"(
      _reserve?: string | null,
      _user?: string | null,
      _amount?: null,
      _timestamp?: null
    ): TypedEventFilter<
      [string, string, BigNumber, BigNumber],
      {
        _reserve: string;
        _user: string;
        _amount: BigNumber;
        _timestamp: BigNumber;
      }
    >;

    RedeemUnderlying(
      _reserve?: string | null,
      _user?: string | null,
      _amount?: null,
      _timestamp?: null
    ): TypedEventFilter<
      [string, string, BigNumber, BigNumber],
      {
        _reserve: string;
        _user: string;
        _amount: BigNumber;
        _timestamp: BigNumber;
      }
    >;

    "ReserveActivated(address)"(
      _reserve?: string | null
    ): TypedEventFilter<[string], { _reserve: string }>;

    ReserveActivated(
      _reserve?: string | null
    ): TypedEventFilter<[string], { _reserve: string }>;

    "ReserveDeactivated(address)"(
      _reserve?: string | null
    ): TypedEventFilter<[string], { _reserve: string }>;

    ReserveDeactivated(
      _reserve?: string | null
    ): TypedEventFilter<[string], { _reserve: string }>;

    "ReserveInitialized(address,address,address,address)"(
      _reserve?: string | null,
      _jdToken?: string | null,
      _sdToken?: string | null,
      _interestRateStrategyAddress?: null
    ): TypedEventFilter<
      [string, string, string, string],
      {
        _reserve: string;
        _jdToken: string;
        _sdToken: string;
        _interestRateStrategyAddress: string;
      }
    >;

    ReserveInitialized(
      _reserve?: string | null,
      _jdToken?: string | null,
      _sdToken?: string | null,
      _interestRateStrategyAddress?: null
    ): TypedEventFilter<
      [string, string, string, string],
      {
        _reserve: string;
        _jdToken: string;
        _sdToken: string;
        _interestRateStrategyAddress: string;
      }
    >;

    "ReserveUpdated(address,uint256,uint256,uint256)"(
      reserve?: string | null,
      liquidityRate?: null,
      currentJuniorLiquidityIndex?: null,
      currentSeniorLiquidityIndex?: null
    ): TypedEventFilter<
      [string, BigNumber, BigNumber, BigNumber],
      {
        reserve: string;
        liquidityRate: BigNumber;
        currentJuniorLiquidityIndex: BigNumber;
        currentSeniorLiquidityIndex: BigNumber;
      }
    >;

    ReserveUpdated(
      reserve?: string | null,
      liquidityRate?: null,
      currentJuniorLiquidityIndex?: null,
      currentSeniorLiquidityIndex?: null
    ): TypedEventFilter<
      [string, BigNumber, BigNumber, BigNumber],
      {
        reserve: string;
        liquidityRate: BigNumber;
        currentJuniorLiquidityIndex: BigNumber;
        currentSeniorLiquidityIndex: BigNumber;
      }
    >;
  };

  estimateGas: {
    activateReserve(
      _reserve: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    claimOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    deactivateReserve(
      _reserve: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    depositLiquidity(
      _reserve: string,
      _tranche: BigNumberish,
      _amount: BigNumberish,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    getReserveAvailableLiquidity(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getReserveJDTokenAddress(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getReserveNormalizedIncome(
      _reserve: string,
      _tranche: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getReserveSDTokenAddress(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getReserveTotalLiquidity(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    initReserve(
      _reserve: string,
      _underlyingAssetDecimals: BigNumberish,
      _interestRateStrategyAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    initReserveWithData(
      _reserve: string,
      _jdTokenName: string,
      _jdTokenSymbol: string,
      _sdTokenName: string,
      _sdTokenSymbol: string,
      _underlyingAssetDecimals: BigNumberish,
      _interestRateStrategyAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    isOwner(overrides?: CallOverrides): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    pendingOwner(overrides?: CallOverrides): Promise<BigNumber>;

    redeemUnderlying(
      _reserve: string,
      _tranche: BigNumberish,
      _user: string,
      _amount: BigNumberish,
      _aTokenBalanceAfterRedeem: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    activateReserve(
      _reserve: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    claimOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    deactivateReserve(
      _reserve: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    depositLiquidity(
      _reserve: string,
      _tranche: BigNumberish,
      _amount: BigNumberish,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    getReserveAvailableLiquidity(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getReserveJDTokenAddress(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getReserveNormalizedIncome(
      _reserve: string,
      _tranche: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getReserveSDTokenAddress(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getReserveTotalLiquidity(
      _reserve: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    initReserve(
      _reserve: string,
      _underlyingAssetDecimals: BigNumberish,
      _interestRateStrategyAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    initReserveWithData(
      _reserve: string,
      _jdTokenName: string,
      _jdTokenSymbol: string,
      _sdTokenName: string,
      _sdTokenSymbol: string,
      _underlyingAssetDecimals: BigNumberish,
      _interestRateStrategyAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    isOwner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    pendingOwner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    redeemUnderlying(
      _reserve: string,
      _tranche: BigNumberish,
      _user: string,
      _amount: BigNumberish,
      _aTokenBalanceAfterRedeem: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;
  };
}

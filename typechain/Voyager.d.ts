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

interface VoyagerInterface extends ethers.utils.Interface {
  functions: {
    "addressResolver()": FunctionFragment;
    "claimOwnership()": FunctionFragment;
    "getAddressResolverAddress()": FunctionFragment;
    "getLiquidityManagerName()": FunctionFragment;
    "getLoanManagerName()": FunctionFragment;
    "getVaultManagerName()": FunctionFragment;
    "getVaultStorageName()": FunctionFragment;
    "isOwner()": FunctionFragment;
    "liquidityManagerName()": FunctionFragment;
    "loanManagerName()": FunctionFragment;
    "owner()": FunctionFragment;
    "pendingOwner()": FunctionFragment;
    "setAddressResolverAddress(address)": FunctionFragment;
    "transferOwnership(address)": FunctionFragment;
    "vaultManagerName()": FunctionFragment;
    "vaultStorageName()": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "addressResolver",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "claimOwnership",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getAddressResolverAddress",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getLiquidityManagerName",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getLoanManagerName",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getVaultManagerName",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getVaultStorageName",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "isOwner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "liquidityManagerName",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "loanManagerName",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "pendingOwner",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "setAddressResolverAddress",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "vaultManagerName",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "vaultStorageName",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "addressResolver",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "claimOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getAddressResolverAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getLiquidityManagerName",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getLoanManagerName",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getVaultManagerName",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getVaultStorageName",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "isOwner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "liquidityManagerName",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "loanManagerName",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "pendingOwner",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setAddressResolverAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "vaultManagerName",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "vaultStorageName",
    data: BytesLike
  ): Result;

  events: {
    "OwnershipTransferred(address,address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
}

export type OwnershipTransferredEvent = TypedEvent<
  [string, string] & { previousOwner: string; newOwner: string }
>;

export class Voyager extends BaseContract {
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

  interface: VoyagerInterface;

  functions: {
    addressResolver(overrides?: CallOverrides): Promise<[string]>;

    claimOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    getAddressResolverAddress(overrides?: CallOverrides): Promise<[string]>;

    getLiquidityManagerName(overrides?: CallOverrides): Promise<[string]>;

    getLoanManagerName(overrides?: CallOverrides): Promise<[string]>;

    getVaultManagerName(overrides?: CallOverrides): Promise<[string]>;

    getVaultStorageName(overrides?: CallOverrides): Promise<[string]>;

    isOwner(overrides?: CallOverrides): Promise<[boolean]>;

    liquidityManagerName(overrides?: CallOverrides): Promise<[string]>;

    loanManagerName(overrides?: CallOverrides): Promise<[string]>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    pendingOwner(overrides?: CallOverrides): Promise<[string]>;

    setAddressResolverAddress(
      _addressResolver: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    vaultManagerName(overrides?: CallOverrides): Promise<[string]>;

    vaultStorageName(overrides?: CallOverrides): Promise<[string]>;
  };

  addressResolver(overrides?: CallOverrides): Promise<string>;

  claimOwnership(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  getAddressResolverAddress(overrides?: CallOverrides): Promise<string>;

  getLiquidityManagerName(overrides?: CallOverrides): Promise<string>;

  getLoanManagerName(overrides?: CallOverrides): Promise<string>;

  getVaultManagerName(overrides?: CallOverrides): Promise<string>;

  getVaultStorageName(overrides?: CallOverrides): Promise<string>;

  isOwner(overrides?: CallOverrides): Promise<boolean>;

  liquidityManagerName(overrides?: CallOverrides): Promise<string>;

  loanManagerName(overrides?: CallOverrides): Promise<string>;

  owner(overrides?: CallOverrides): Promise<string>;

  pendingOwner(overrides?: CallOverrides): Promise<string>;

  setAddressResolverAddress(
    _addressResolver: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  transferOwnership(
    newOwner: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  vaultManagerName(overrides?: CallOverrides): Promise<string>;

  vaultStorageName(overrides?: CallOverrides): Promise<string>;

  callStatic: {
    addressResolver(overrides?: CallOverrides): Promise<string>;

    claimOwnership(overrides?: CallOverrides): Promise<void>;

    getAddressResolverAddress(overrides?: CallOverrides): Promise<string>;

    getLiquidityManagerName(overrides?: CallOverrides): Promise<string>;

    getLoanManagerName(overrides?: CallOverrides): Promise<string>;

    getVaultManagerName(overrides?: CallOverrides): Promise<string>;

    getVaultStorageName(overrides?: CallOverrides): Promise<string>;

    isOwner(overrides?: CallOverrides): Promise<boolean>;

    liquidityManagerName(overrides?: CallOverrides): Promise<string>;

    loanManagerName(overrides?: CallOverrides): Promise<string>;

    owner(overrides?: CallOverrides): Promise<string>;

    pendingOwner(overrides?: CallOverrides): Promise<string>;

    setAddressResolverAddress(
      _addressResolver: string,
      overrides?: CallOverrides
    ): Promise<void>;

    transferOwnership(
      newOwner: string,
      overrides?: CallOverrides
    ): Promise<void>;

    vaultManagerName(overrides?: CallOverrides): Promise<string>;

    vaultStorageName(overrides?: CallOverrides): Promise<string>;
  };

  filters: {
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
  };

  estimateGas: {
    addressResolver(overrides?: CallOverrides): Promise<BigNumber>;

    claimOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    getAddressResolverAddress(overrides?: CallOverrides): Promise<BigNumber>;

    getLiquidityManagerName(overrides?: CallOverrides): Promise<BigNumber>;

    getLoanManagerName(overrides?: CallOverrides): Promise<BigNumber>;

    getVaultManagerName(overrides?: CallOverrides): Promise<BigNumber>;

    getVaultStorageName(overrides?: CallOverrides): Promise<BigNumber>;

    isOwner(overrides?: CallOverrides): Promise<BigNumber>;

    liquidityManagerName(overrides?: CallOverrides): Promise<BigNumber>;

    loanManagerName(overrides?: CallOverrides): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    pendingOwner(overrides?: CallOverrides): Promise<BigNumber>;

    setAddressResolverAddress(
      _addressResolver: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    vaultManagerName(overrides?: CallOverrides): Promise<BigNumber>;

    vaultStorageName(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    addressResolver(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    claimOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    getAddressResolverAddress(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getLiquidityManagerName(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getLoanManagerName(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getVaultManagerName(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getVaultStorageName(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isOwner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    liquidityManagerName(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    loanManagerName(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    pendingOwner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    setAddressResolverAddress(
      _addressResolver: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    vaultManagerName(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    vaultStorageName(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
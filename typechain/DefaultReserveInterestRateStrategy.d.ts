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
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";

interface DefaultReserveInterestRateStrategyInterface
  extends ethers.utils.Interface {
  functions: {
    "EXCESS_UTILIZATION_RATE()": FunctionFragment;
    "OPTIMAL_UTILIZATION_RATE()": FunctionFragment;
    "baseVariableBorrowRate()": FunctionFragment;
    "getBaseVariableBorrowRate()": FunctionFragment;
    "getStableRateSlope1()": FunctionFragment;
    "getStableRateSlope2()": FunctionFragment;
    "getVariableRateSlope1()": FunctionFragment;
    "getVariableRateSlope2()": FunctionFragment;
    "reserve()": FunctionFragment;
    "stableRateSlope1()": FunctionFragment;
    "stableRateSlope2()": FunctionFragment;
    "variableRateSlope1()": FunctionFragment;
    "variableRateSlope2()": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "EXCESS_UTILIZATION_RATE",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "OPTIMAL_UTILIZATION_RATE",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "baseVariableBorrowRate",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getBaseVariableBorrowRate",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getStableRateSlope1",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getStableRateSlope2",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getVariableRateSlope1",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getVariableRateSlope2",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "reserve", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "stableRateSlope1",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "stableRateSlope2",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "variableRateSlope1",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "variableRateSlope2",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "EXCESS_UTILIZATION_RATE",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "OPTIMAL_UTILIZATION_RATE",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "baseVariableBorrowRate",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getBaseVariableBorrowRate",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getStableRateSlope1",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getStableRateSlope2",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getVariableRateSlope1",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getVariableRateSlope2",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "reserve", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "stableRateSlope1",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "stableRateSlope2",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "variableRateSlope1",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "variableRateSlope2",
    data: BytesLike
  ): Result;

  events: {};
}

export class DefaultReserveInterestRateStrategy extends BaseContract {
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

  interface: DefaultReserveInterestRateStrategyInterface;

  functions: {
    EXCESS_UTILIZATION_RATE(overrides?: CallOverrides): Promise<[BigNumber]>;

    OPTIMAL_UTILIZATION_RATE(overrides?: CallOverrides): Promise<[BigNumber]>;

    baseVariableBorrowRate(overrides?: CallOverrides): Promise<[BigNumber]>;

    getBaseVariableBorrowRate(overrides?: CallOverrides): Promise<[BigNumber]>;

    getStableRateSlope1(overrides?: CallOverrides): Promise<[BigNumber]>;

    getStableRateSlope2(overrides?: CallOverrides): Promise<[BigNumber]>;

    getVariableRateSlope1(overrides?: CallOverrides): Promise<[BigNumber]>;

    getVariableRateSlope2(overrides?: CallOverrides): Promise<[BigNumber]>;

    reserve(overrides?: CallOverrides): Promise<[string]>;

    stableRateSlope1(overrides?: CallOverrides): Promise<[BigNumber]>;

    stableRateSlope2(overrides?: CallOverrides): Promise<[BigNumber]>;

    variableRateSlope1(overrides?: CallOverrides): Promise<[BigNumber]>;

    variableRateSlope2(overrides?: CallOverrides): Promise<[BigNumber]>;
  };

  EXCESS_UTILIZATION_RATE(overrides?: CallOverrides): Promise<BigNumber>;

  OPTIMAL_UTILIZATION_RATE(overrides?: CallOverrides): Promise<BigNumber>;

  baseVariableBorrowRate(overrides?: CallOverrides): Promise<BigNumber>;

  getBaseVariableBorrowRate(overrides?: CallOverrides): Promise<BigNumber>;

  getStableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

  getStableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

  getVariableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

  getVariableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

  reserve(overrides?: CallOverrides): Promise<string>;

  stableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

  stableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

  variableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

  variableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

  callStatic: {
    EXCESS_UTILIZATION_RATE(overrides?: CallOverrides): Promise<BigNumber>;

    OPTIMAL_UTILIZATION_RATE(overrides?: CallOverrides): Promise<BigNumber>;

    baseVariableBorrowRate(overrides?: CallOverrides): Promise<BigNumber>;

    getBaseVariableBorrowRate(overrides?: CallOverrides): Promise<BigNumber>;

    getStableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

    getStableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

    getVariableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

    getVariableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

    reserve(overrides?: CallOverrides): Promise<string>;

    stableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

    stableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

    variableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

    variableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;
  };

  filters: {};

  estimateGas: {
    EXCESS_UTILIZATION_RATE(overrides?: CallOverrides): Promise<BigNumber>;

    OPTIMAL_UTILIZATION_RATE(overrides?: CallOverrides): Promise<BigNumber>;

    baseVariableBorrowRate(overrides?: CallOverrides): Promise<BigNumber>;

    getBaseVariableBorrowRate(overrides?: CallOverrides): Promise<BigNumber>;

    getStableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

    getStableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

    getVariableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

    getVariableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

    reserve(overrides?: CallOverrides): Promise<BigNumber>;

    stableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

    stableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;

    variableRateSlope1(overrides?: CallOverrides): Promise<BigNumber>;

    variableRateSlope2(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    EXCESS_UTILIZATION_RATE(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    OPTIMAL_UTILIZATION_RATE(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    baseVariableBorrowRate(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getBaseVariableBorrowRate(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getStableRateSlope1(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getStableRateSlope2(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getVariableRateSlope1(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getVariableRateSlope2(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    reserve(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    stableRateSlope1(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    stableRateSlope2(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    variableRateSlope1(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    variableRateSlope2(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}

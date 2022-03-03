/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { ethers } from "ethers";
import {
  FactoryOptions,
  HardhatEthersHelpers as HardhatEthersHelpersBase,
} from "@nomiclabs/hardhat-ethers/types";

import * as Contracts from ".";

declare module "hardhat/types/runtime" {
  interface HardhatEthersHelpers extends HardhatEthersHelpersBase {
    getContractFactory(
      name: "AddressResolver",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AddressResolver__factory>;
    getContractFactory(
      name: "DefaultReserveInterestRateStrategy",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.DefaultReserveInterestRateStrategy__factory>;
    getContractFactory(
      name: "LiquidityManager",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.LiquidityManager__factory>;
    getContractFactory(
      name: "Vault",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Vault__factory>;
    getContractFactory(
      name: "VaultManager",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.VaultManager__factory>;
    getContractFactory(
      name: "VaultStorage",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.VaultStorage__factory>;
    getContractFactory(
      name: "Voyager",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Voyager__factory>;
    getContractFactory(
      name: "IAddressResolver",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAddressResolver__factory>;
    getContractFactory(
      name: "ICreditAccount",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ICreditAccount__factory>;
    getContractFactory(
      name: "IERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20__factory>;
    getContractFactory(
      name: "ILendingRateOracle",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ILendingRateOracle__factory>;
    getContractFactory(
      name: "IReserveInterestRateStrategy",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IReserveInterestRateStrategy__factory>;
    getContractFactory(
      name: "IReserveManager",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IReserveManager__factory>;
    getContractFactory(
      name: "IVaultManager",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IVaultManager__factory>;
    getContractFactory(
      name: "Escrow",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Escrow__factory>;
    getContractFactory(
      name: "Errors",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Errors__factory>;
    getContractFactory(
      name: "IStableDebtToken",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IStableDebtToken__factory>;
    getContractFactory(
      name: "Ownable",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Ownable__factory>;
    getContractFactory(
      name: "ReserveManager",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ReserveManager__factory>;
    getContractFactory(
      name: "State",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.State__factory>;
    getContractFactory(
      name: "ReentrancyGuard",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ReentrancyGuard__factory>;
    getContractFactory(
      name: "BaseERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BaseERC20__factory>;
    getContractFactory(
      name: "JuniorDepositToken",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.JuniorDepositToken__factory>;
    getContractFactory(
      name: "SeniorDepositToken",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.SeniorDepositToken__factory>;
    getContractFactory(
      name: "StableDebtToken",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.StableDebtToken__factory>;
    getContractFactory(
      name: "AccessControl",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.AccessControl__factory>;
    getContractFactory(
      name: "IAccessControl",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IAccessControl__factory>;
    getContractFactory(
      name: "Ownable",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Ownable__factory>;
    getContractFactory(
      name: "ERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC20__factory>;
    getContractFactory(
      name: "IERC20Metadata",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20Metadata__factory>;
    getContractFactory(
      name: "IERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20__factory>;
    getContractFactory(
      name: "ERC165",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC165__factory>;
    getContractFactory(
      name: "IERC165",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC165__factory>;

    getContractAt(
      name: "AddressResolver",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AddressResolver>;
    getContractAt(
      name: "DefaultReserveInterestRateStrategy",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.DefaultReserveInterestRateStrategy>;
    getContractAt(
      name: "LiquidityManager",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.LiquidityManager>;
    getContractAt(
      name: "Vault",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Vault>;
    getContractAt(
      name: "VaultManager",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.VaultManager>;
    getContractAt(
      name: "VaultStorage",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.VaultStorage>;
    getContractAt(
      name: "Voyager",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Voyager>;
    getContractAt(
      name: "IAddressResolver",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAddressResolver>;
    getContractAt(
      name: "ICreditAccount",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ICreditAccount>;
    getContractAt(
      name: "IERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20>;
    getContractAt(
      name: "ILendingRateOracle",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ILendingRateOracle>;
    getContractAt(
      name: "IReserveInterestRateStrategy",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IReserveInterestRateStrategy>;
    getContractAt(
      name: "IReserveManager",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IReserveManager>;
    getContractAt(
      name: "IVaultManager",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IVaultManager>;
    getContractAt(
      name: "Escrow",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Escrow>;
    getContractAt(
      name: "Errors",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Errors>;
    getContractAt(
      name: "IStableDebtToken",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IStableDebtToken>;
    getContractAt(
      name: "Ownable",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Ownable>;
    getContractAt(
      name: "ReserveManager",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ReserveManager>;
    getContractAt(
      name: "State",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.State>;
    getContractAt(
      name: "ReentrancyGuard",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ReentrancyGuard>;
    getContractAt(
      name: "BaseERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.BaseERC20>;
    getContractAt(
      name: "JuniorDepositToken",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.JuniorDepositToken>;
    getContractAt(
      name: "SeniorDepositToken",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.SeniorDepositToken>;
    getContractAt(
      name: "StableDebtToken",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.StableDebtToken>;
    getContractAt(
      name: "AccessControl",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.AccessControl>;
    getContractAt(
      name: "IAccessControl",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IAccessControl>;
    getContractAt(
      name: "Ownable",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Ownable>;
    getContractAt(
      name: "ERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC20>;
    getContractAt(
      name: "IERC20Metadata",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20Metadata>;
    getContractAt(
      name: "IERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20>;
    getContractAt(
      name: "ERC165",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC165>;
    getContractAt(
      name: "IERC165",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC165>;

    // default types
    getContractFactory(
      name: string,
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<ethers.ContractFactory>;
    getContractFactory(
      abi: any[],
      bytecode: ethers.utils.BytesLike,
      signer?: ethers.Signer
    ): Promise<ethers.ContractFactory>;
    getContractAt(
      nameOrAbi: string | any[],
      address: string,
      signer?: ethers.Signer
    ): Promise<ethers.Contract>;
  }
}

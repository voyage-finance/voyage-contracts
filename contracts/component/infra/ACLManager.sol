// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";

contract ACLManager is AccessControl, IACLManager {
    bytes32 public constant VOYAGER_ADMIN_ROLE = keccak256("VOYAGER_ADMIN");

    bytes32 public constant LIQUIDITY_MANAGER_CONTRACT_ROLE =
        keccak256("LIQUIDITY_MANAGER_CONTRACT");

    bytes32 public constant LIQUIDITY_MANAGER_ADMIN_ROLE =
        keccak256("LIQUIDITY_MANAGER_ADMIN");

    bytes32 public constant VAULT_MANAGER_ADMIN_ROLE =
        keccak256("VAULT_MANAGER_ADMIN");

    bytes32 public constant VAULT_MANAGER_CONTRACT_ROLE =
        keccak256("VAULT_MANAGER_CONTRACT");

    bytes32 public constant LOAN_MANAGER_ADMIN_ROLE =
        keccak256("LOAN_MANAGER_ADMIN");

    bytes32 public constant LOAN_MANAGER_CONTRACT_ROLE =
        keccak256("LOAN_MANAGER_CONTRACT");

    bytes32 public constant VAULT_CONFIGURATOR =
        keccak256("VAULT_CONFIGURATOR");

    bytes32 public constant VOYAGER_CONTRACT_ROLE =
        keccak256("VOYAGER_CONTRACT");

    bytes32 public constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER");

    constructor(address _aclAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _aclAdmin);
    }

    function grantLiquidityManagerContract(address _admin) external {
        grantRole(LIQUIDITY_MANAGER_CONTRACT_ROLE, _admin);
    }

    function isLiquidityManagerContract(address _admin)
        external
        view
        returns (bool)
    {
        return hasRole(LIQUIDITY_MANAGER_CONTRACT_ROLE, _admin);
    }

    function grantLiquidityManager(address _admin) external {
        grantRole(LIQUIDITY_MANAGER_ADMIN_ROLE, _admin);
    }

    function isLiquidityManager(address _admin) external view returns (bool) {
        return hasRole(LIQUIDITY_MANAGER_ADMIN_ROLE, _admin);
    }

    function grantLoanManagerContract(address _admin) external {
        grantRole(LOAN_MANAGER_CONTRACT_ROLE, _admin);
    }

    function isLoanManagerContract(address _admin)
        external
        view
        returns (bool)
    {
        return hasRole(LOAN_MANAGER_CONTRACT_ROLE, _admin);
    }

    function grantLoanManager(address _admin) external {
        grantRole(LOAN_MANAGER_ADMIN_ROLE, _admin);
    }

    function isLoanManager(address _admin) external view returns (bool) {
        return hasRole(LOAN_MANAGER_ADMIN_ROLE, _admin);
    }

    function grantVaultManager(address _admin) external {
        grantRole(VAULT_MANAGER_ADMIN_ROLE, _admin);
    }

    function isVaultManager(address _admin) external view returns (bool) {
        return hasRole(VAULT_MANAGER_ADMIN_ROLE, _admin);
    }

    function grantVaultManagerContract(address _admin) external {
        grantRole(VAULT_MANAGER_CONTRACT_ROLE, _admin);
    }

    function isVaultManagerContract(address _admin)
        external
        view
        returns (bool)
    {
        return hasRole(VAULT_MANAGER_CONTRACT_ROLE, _admin);
    }

    function grantPoolManager(address _admin) external {
        grantRole(VOYAGER_ADMIN_ROLE, _admin);
    }

    function isProtocolManager(address _admin) external view returns (bool) {
        return hasRole(VOYAGER_ADMIN_ROLE, _admin);
    }

    function grantVaultConfigurator(address _amin) external {
        grantRole(VAULT_CONFIGURATOR, _amin);
    }

    function isVaultConfigurator(address _admin) external view returns (bool) {
        return hasRole(VAULT_CONFIGURATOR, _admin);
    }

    function grantVoyagerContract(address _admin) external {
        grantRole(VOYAGER_CONTRACT_ROLE, _admin);
    }

    function isVoyagerContract(address _admin) external view returns (bool) {
        return hasRole(VOYAGER_CONTRACT_ROLE, _admin);
    }

    function grantOracleManager(address _admin) external {
        grantRole(ORACLE_MANAGER_ROLE, _admin);
    }

    function isOracleManager(address _admin) external view returns (bool) {
        return hasRole(ORACLE_MANAGER_ROLE, _admin);
    }
}

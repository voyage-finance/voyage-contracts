// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import '../../interfaces/IACLManager.sol';

contract ACLManager is AccessControl, IACLManager {
    bytes32 public constant VOYAGER_ADMIN_ROLE = keccak256('VOYAGER_ADMIN');

    bytes32 public constant LIQUIDITY_MANAGER_ADMIN_ROLE =
        keccak256('LIQUIDITY_MANAGER_ADMIN');

    bytes32 public constant VAULT_MANAGER_ADMIN_ROLE =
        keccak256('VAULT_MANAGER_ADMIN');

    constructor(address _aclAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _aclAdmin);
    }

    function grantLiquidityManager(address _admin) external {
        grantRole(LIQUIDITY_MANAGER_ADMIN_ROLE, _admin);
    }

    function isLiquidityManager(address _admin) external view returns (bool) {
        return hasRole(LIQUIDITY_MANAGER_ADMIN_ROLE, _admin);
    }

    function grantVaultManager(address _admin) external {
        grantRole(VAULT_MANAGER_ADMIN_ROLE, _admin);
    }

    function isVaultManager(address _admin) external view returns (bool) {
        return hasRole(VAULT_MANAGER_ADMIN_ROLE, _admin);
    }

    function grantPoolManager(address _admin) external {
        grantRole(VOYAGER_ADMIN_ROLE, _admin);
    }

    function isProtocolManager(address _admin) external view returns (bool) {
        return hasRole(VOYAGER_ADMIN_ROLE, _admin);
    }
}

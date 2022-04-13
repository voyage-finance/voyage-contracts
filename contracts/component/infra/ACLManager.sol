// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import '../../interfaces/IACLManager.sol';

contract ACLManager is AccessControl, IACLManager {
    bytes32 public constant PROTOCOL_CONFIGURE_ADMIN_ROLE =
        keccak256('PROTOCOL_CONFIGURE_ADMIN');

    bytes32 public constant LIQUIDITY_MANAGER_ADMIN_ROLE =
        keccak256('LIQUIDITY_MANAGER_ADMIN');

    bytes32 public constant VAULT_MANAGER_ADMIN_ROLE =
        keccak256('VAULT_MANAGER_ADMIN');

    constructor(address _aclAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _aclAdmin);
    }

    function isLiquidityManager(address _admin) external view returns (bool) {
        return hasRole(LIQUIDITY_MANAGER_ADMIN_ROLE, _admin);
    }

    function isVaultManager(address _admin) external view returns (bool) {
        return hasRole(VAULT_MANAGER_ADMIN_ROLE, _admin);
    }

    function isProtocolConfigure(address _admin) external view returns (bool) {
        return hasRole(PROTOCOL_CONFIGURE_ADMIN_ROLE, _admin);
    }
}

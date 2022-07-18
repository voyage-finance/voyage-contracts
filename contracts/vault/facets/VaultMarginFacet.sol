// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {CustodyData, VaultStorageV1, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {IMarginEscrow} from "../interfaces/IMarginEscrow.sol";
import {VaultConfig} from "../../voyage/libraries/LibAppStorage.sol";
import {DataProviderFacet} from "../../voyage/facets/DataProviderFacet.sol";
import {PaymentsFacet} from "../../shared/facets/PaymentsFacet.sol";

contract VaultMarginFacet is ReentrancyGuard, Storage {
    /// @notice Transfer some margin deposit
    /// @param _sponsor address of margin depositer
    /// @param _reserve reserve address
    /// @param _amount deposit amount
    function depositMargin(
        address _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable nonReentrant onlyVoyage {
        VaultConfig memory vaultConfig = DataProviderFacet(
            LibVaultStorage.diamondStorage().voyage
        ).getVaultConfig(_reserve);
        IMarginEscrow me = _marginEscrow(_reserve);
        if (address(me) == address(0)) {
            revert VaultNotInitialised();
        }
        uint256 maxAllowedAmount = vaultConfig.maxMargin;
        uint256 depositedAmount = me.totalMargin();
        if (depositedAmount + _amount > maxAllowedAmount) {
            revert InvalidDeposit("deposit amount exceed");
        }
        uint256 minAllowedAmount = vaultConfig.minMargin;
        if (minAllowedAmount > _amount) {
            revert InvalidDeposit("deposit too small");
        }
        PaymentsFacet(address(this)).pullToken(
            me.asset(),
            _amount,
            _sponsor,
            address(this)
        );
        me.deposit(_amount, _sponsor);
    }

    /// @notice Redeem underlying reserve
    /// @param _sponsor sponsor address
    /// @param _reserve reserve address
    /// @param _amount redeem amount
    function redeemMargin(
        address payable _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable nonReentrant onlyVoyage {
        IMarginEscrow me = _marginEscrow(_reserve);
        if (address(me) == address(0)) {
            revert VaultNotInitialised();
        }
        me.withdraw(_amount, _sponsor, _sponsor);
    }

    /// @return Returns the actual value that has been transferred
    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) external nonReentrant onlyVoyage returns (uint256) {
        IMarginEscrow me = _marginEscrow(_reserve);
        return me.slash(_amount, _to);
    }
}

/* --------------------------------- errors -------------------------------- */
error VaultNotInitialised();
error InvalidDeposit(string reason);

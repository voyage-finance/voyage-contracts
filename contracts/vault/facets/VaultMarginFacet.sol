// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {CustodyData, VaultStorageV1, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {IMarginEscrow} from "../interfaces/IMarginEscrow.sol";
import {VaultConfig} from "../../voyage/libraries/LibAppStorage.sol";
import {PaymentsFacet} from "../../shared/facets/PaymentsFacet.sol";
import {VaultFacet} from "../../voyage/facets/VaultFacet.sol";

contract VaultMarginFacet is ReentrancyGuard, Storage {
    /// @notice Transfer some margin deposit
    /// @param _sponsor address of margin depositer
    /// @param _collection collection address
    /// @param _amount deposit amount
    function depositMargin(
        address _sponsor,
        address _collection,
        uint256 _amount
    ) external payable nonReentrant onlyVoyage {
        VaultConfig memory vc = VaultFacet(LibVaultStorage.ds().voyage)
            .getVaultConfig(_collection, address(this));
        IMarginEscrow me = _marginEscrow(vc.currency);
        if (address(me) == address(0)) {
            revert VaultNotInitialised();
        }
        uint256 depositedAmount = me.totalMargin();
        if (depositedAmount + _amount > vc.maxMargin) {
            revert InvalidDeposit("deposit amount exceed");
        }
        if (vc.minMargin > _amount) {
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
    /// @param _collection collection address
    /// @param _amount redeem amount
    function redeemMargin(
        address payable _sponsor,
        address _collection,
        uint256 _amount
    ) external payable nonReentrant onlyVoyage {
        VaultConfig memory vc = VaultFacet(LibVaultStorage.ds().voyage)
            .getVaultConfig(_collection, address(this));
        IMarginEscrow me = _marginEscrow(vc.currency);
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

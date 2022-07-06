// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ILoanStrategy} from "../interfaces/ILoanStrategy.sol";

contract DefaultLoanStrategy is ILoanStrategy {
    uint256 public immutable term;

    uint256 public immutable epoch;

    uint256 public immutable grace;

    // express in ray
    uint256 public immutable liquidationBonus;

    // express in ray
    uint256 public immutable marginRequirement;

    constructor(
        uint256 _term,
        uint256 _epoch,
        uint256 _grace,
        uint256 _liquidationBonus,
        uint256 _marginRequirement
    ) public {
        term = _term;
        epoch = _epoch;
        grace = _grace;
        liquidationBonus = _liquidationBonus;
        marginRequirement = _marginRequirement;
    }

    function getTerm() external view returns (uint256) {
        return term;
    }

    function getEpoch() external view returns (uint256) {
        return epoch;
    }

    function getGrace() external view returns (uint256) {
        return grace;
    }

    function getLiquidateBonus() external view returns (uint256) {
        return liquidationBonus;
    }

    function getMarginRequirement() external view returns (uint256) {
        return marginRequirement;
    }

    function getLiquidationParams()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (grace, liquidationBonus, marginRequirement);
    }
}

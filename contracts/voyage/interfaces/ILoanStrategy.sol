// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface ILoanStrategy {
    function getTerm() external view returns (uint256);

    function getEpoch() external view returns (uint256);

    function getGrace() external view returns (uint256);

    function getLiquidateBonus() external view returns (uint256);

    function getMarginRequirement() external view returns (uint256);

    function getLiquidationParams()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

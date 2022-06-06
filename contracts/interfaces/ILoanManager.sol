// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/types/DataTypes.sol';

interface ILoanManager {
    function getVaultDebt(address _reserve, address _vault)
        external
        view
        returns (uint256, uint256);

    function getDrawDownList(address _reserve, address _vault)
        external
        view
        returns (uint256, uint256);

    function getDrawDownDetail(
        address _reserve,
        address _vault,
        uint256 _drawDownId
    ) external view returns (DataTypes.DebtDetail memory);
}

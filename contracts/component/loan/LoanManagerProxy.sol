// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../../libraries/proxy/Proxy.sol";
import "./LoanManager.sol";
import "../../interfaces/ILoanManagerProxy.sol";

contract LoanManagerProxy is ILoanManagerProxy, Proxy {
    function getVaultDebt(address _reserve, address _vault)
        external
        view
        returns (uint256, uint256)
    {
        return LoanManager(address(target)).getVaultDebt(_reserve, _vault);
    }

    function getDrawDownList(address _reserve, address _vault)
        external
        view
        returns (uint256, uint256)
    {
        return LoanManager(address(target)).getDrawDownList(_reserve, _vault);
    }

    function getDrawDownDetail(
        address _reserve,
        address _vault,
        uint256 _drawDownId
    ) external view returns (DataTypes.DebtDetail memory) {
        return
            LoanManager(address(target)).getDrawDownDetail(
                _reserve,
                _vault,
                _drawDownId
            );
    }

    function principalBalance(address _asset) external view returns (uint256) {
        return LoanManager(address(target)).principalBalance(_asset);
    }
}

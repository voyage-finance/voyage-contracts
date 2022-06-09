pragma solidity ^0.8.9;

import {Proxyable} from "../libraries/proxy/Proxyable.sol";
import {ILoanManager} from "../interfaces/ILoanManager.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

contract MockLoanManager is ILoanManager, Proxyable {
    uint256 internal _principalBalance;
    uint256 internal _interestBalance;

    constructor(
        uint256 principal,
        uint256 interest,
        address payable _proxy
    ) Proxyable(_proxy) {
        _principalBalance = principal;
        _interestBalance = interest;
    }

    function borrow(
        address _user,
        address _asset,
        uint256 _amount,
        address payable _vault,
        uint256 _grossAssetValue
    ) external {}

    function repay(
        address _user,
        address _asset,
        uint256 _drawDown,
        uint256 _amount,
        address payable _vault
    ) external {}

    function principalBalance(address underlying)
        external
        view
        returns (uint256)
    {
        return _principalBalance;
    }

    function interestBalance(address underlying)
        external
        view
        returns (uint256)
    {
        return _interestBalance;
    }

    function getVaultDebt(address _reserve, address _vault)
        external
        view
        returns (uint256, uint256)
    {
        return (0, 0);
    }

    function getDrawDownList(address _reserve, address _vault)
        external
        view
        returns (uint256, uint256)
    {
        return (0, 0);
    }

    function getDrawDownDetail(
        address _reserve,
        address _vault,
        uint256 _drawDownId
    ) external view returns (DataTypes.DebtDetail memory) {
        DataTypes.DebtDetail memory mockVal;
        return mockVal;
    }
}

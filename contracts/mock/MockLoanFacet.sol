pragma solidity ^0.8.9;

import {Storage, TestStorage} from "./TestStorage.sol";

contract MockLoanFacet is TestStorage {
    function principalBalance(address underlying)
        external
        view
        returns (uint256)
    {
        Storage storage s = testStorage();
        return s.principalBalance;
    }

    function interestBalance(address underlying)
        external
        view
        returns (uint256)
    {
        Storage storage s = testStorage();
        return s.interestBalance;
    }

    function repay(
        address _asset,
        uint256 _loan,
        address payable _vault
    ) external pure {
        revert("not implemented");
    }

    function liquidate(
        address _currency,
        address _vault,
        uint256 _loanId
    ) external {
        revert("not implemented");
    }

    function getVaultDebt(address _currency, address _vault)
        public
        view
        returns (uint256, uint256)
    {
        revert("not implemented");
    }

    function getDiscount(uint256 _value, uint256 _liquidationBonus)
        private
        pure
        returns (uint256)
    {
        revert();
    }
}

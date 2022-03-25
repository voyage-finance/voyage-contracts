// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './BaseERC20.sol';

abstract contract DebtTokenBase is
    BaseERC20('DEBTTOKEN_IMPL', 'DEBTTOKEN_IMPL', 0)
{
    mapping(address => mapping(address => uint256)) internal _borrowAllowances;

    /**
     * @dev Being non transferrable, the debt token does not implement any of the
     * standard ERC20 functions for transfer and allowance.
     **/
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        recipient;
        amount;
        revert('TRANSFER_NOT_SUPPORTED');
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        owner;
        spender;
        revert('ALLOWANCE_NOT_SUPPORTED');
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        amount;
        revert('APPROVAL_NOT_SUPPORTED');
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        sender;
        recipient;
        amount;
        revert('TRANSFER_NOT_SUPPORTED');
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        addedValue;
        revert('ALLOWANCE_NOT_SUPPORTED');
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        subtractedValue;
        revert('ALLOWANCE_NOT_SUPPORTED');
    }

    function _getUnderlyingAssetAddress()
        internal
        view
        virtual
        returns (address);
}

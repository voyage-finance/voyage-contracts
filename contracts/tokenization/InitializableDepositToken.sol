// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './base/InitializableToken.sol';

/**
 * @title IDepositToken
 * @notice Interface for the initialize function on JuniorDepositToken and SeniorDepositToken
 **/
abstract contract InitializableDepositToken is InitializableToken {
    // user address => timestamp => amount
    mapping(address => mapping(uint256 => uint256)) private withdrawals;

    // user address => timestamp array
    mapping(address => uint256[]) private pendingTimestamp;

    uint256 private totalPending;

    uint256 private lockupTime = 7 days;

    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(address indexed from, uint256 value, uint256 index);

    function pushWithdraw(address _user, uint256 _amount) internal {
        require(withdrawals[_user][block.timestamp] == 0, 'invalid withdraw');
        withdrawals[_user][block.timestamp] = _amount;
        pendingTimestamp[_user].push(block.timestamp);
        totalPending += _amount;
    }

    function popWithdraw(address _user, uint256 _index)
        internal
        returns (uint256)
    {
        uint256[] storage times = pendingTimestamp[_user];
        require(_index < times.length, 'invalid index');
        uint256 ts = times[_index];
        require(block.timestamp - ts > lockupTime, 'cool down error');

        uint256 last = times[times.length - 1];
        times[_index] = last;
        times.pop();

        uint256 withdrawable = withdrawals[_user][ts];
        delete withdrawals[_user][ts];
        totalPending -= withdrawable;
        return withdrawable;
    }

    function pendingWithdrawal(address _user)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory times = pendingTimestamp[_user];
        uint256[] memory amounts = new uint256[](times.length);

        for (uint256 i = 0; i < times.length; i++) {
            amounts[i] = withdrawals[_user][times[i]];
        }

        return (times, amounts);
    }

    function totalPendingWithdrawal() public view returns (uint256) {
        return totalPending;
    }

    function withdrawalAble(address _user) public view returns (uint256) {
        uint256[] storage ts = pendingTimestamp[_user];
        uint256 withdrawable = 0;

        for (uint256 i = 0; i < ts.length; i++) {
            withdrawable += withdrawals[_user][ts[i]];
        }
        return withdrawable;
    }

    function lockTime() public view returns (uint256) {
        return lockupTime;
    }
}

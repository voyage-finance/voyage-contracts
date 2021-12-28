// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.9;

import './libraries/ownership/Ownable.sol';
import './libraries/math/SafeMath.sol';
import './libraries/math/SafeMath.sol';
import './libraries/math/WadRayMath.sol';
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract Ownft is Ownable, ReentrancyGuard {

    // last_update_time will be updated when deposit/claim happens
    struct UserInfo {
        address user;
        uint principal;
        uint last_update_time;
    }

    using Address for address;
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using WadRayMath for uint256;

    event Deposit(
        address _token,
        address _user,
        uint256 _amount,
        uint256 _timestamp
    );

    event WhilteListToken(
        address _token,
        bool _enable,
        address _operator
    );

    event InterestRateSet(
        uint256 _interest_rate,
        address _operator
    );

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    mapping(address => bool) _depositWhitelist;

    mapping(address => UserInfo) _userInfo;

    // we are using a fixed golbal interest_rate for investor here
    // better to define a ReservePool if we are going to support
    // multiple deposit assets in the future
    // expressed in Ray
    uint256 _interest_rate;

    constructor(uint256 interest_rate) public {
      _interest_rate = interest_rate;
    }

    function calculateLinearInterest(
        uint256 principal,
        uint256 _rate,
        uint256 _lastUpdateTimestamp
    )
        internal
        view
        returns (uint256)
    {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp.sub(_lastUpdateTimestamp);

        uint256 timeDelta = timeDifference.wadToRay().rayDiv(SECONDS_PER_YEAR.wadToRay());

        return _rate.rayMul(timeDelta).mul(principal);
    }

    // set up assets that can be deposited
    function setDepositWhiteList(
        address token,
        bool enable
    ) onlyOwner external {
        _depositWhitelist[token] = enable;
        emit WhilteListToken(token, enable, msg.sender);
    }

    function setInterestRate(
        uint256 interest_rate
    ) onlyOwner external {
        _interest_rate = interest_rate;
        emit InterestRateSet(interest_rate, msg.sender);
    }

    function deposit(
        address token,
        uint amount
    ) external nonReentrant {
        require(_depositWhitelist[token] == true, 'Ownft: TOKEN NOT ENABLED');
        // update user state
        UserInfo storage user = _userInfo[msg.sender];
        if (user.principal > 0) {
            uint256 pending_rewards = calculateLinearInterest(user.principal, _interest_rate, user.last_update_time);
            ERC20(token).safeTransfer(msg.sender, pending_rewards);
        }
        ERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        user.principal += amount;
        user.last_update_time = block.timestamp;
        emit Deposit(token, msg.sender, amount, block.timestamp);
    }
}
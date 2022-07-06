// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC4626} from "../../shared/interfaces/IERC4626.sol";

interface IMarginEscrow is IERC4626 {
    function initialize(
        address _vault,
        address _voyage,
        address _asset
    ) external;

    function slash(uint256 _amount, address payable _to)
        external
        payable
        returns (uint256);

    function withdrawableMargin(address _user) external view returns (uint256);

    function totalWithdrawableMargin() external view returns (uint256);

    function totalMargin() external view returns (uint256);

    function transferUnderlyingTo(address _target, uint256 _amount) external;
}

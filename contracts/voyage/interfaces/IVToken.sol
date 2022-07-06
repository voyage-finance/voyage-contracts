// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC4626} from "../../shared/interfaces/IERC4626.sol";

interface IVToken is IERC4626 {
    function transferUnderlyingTo(address _target, uint256 _amount) external;

    function claim(uint256 _withdrawlIdx) external;

    function unbonding(address _user)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    function totalUnbonding() external view returns (uint256);
}

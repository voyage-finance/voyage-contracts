// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC20, ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";

abstract contract IVToken is ERC4626 {
    constructor(
        ERC20 _underlyingAsset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_underlyingAsset, _name, _symbol) {}

    function transferUnderlyingTo(address _target, uint256 _amount)
        external
        virtual;

    function claim(uint256 _withdrawlIdx) external virtual;

    function unbonding(address _user)
        external
        view
        virtual
        returns (uint256[] memory, uint256[] memory);

    function totalUnbonding() external view virtual returns (uint256);
}

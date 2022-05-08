// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IVToken {
    function mint(
        address _user,
        uint256 _amount,
        uint256 _index
    ) external returns (bool);

    function burn(
        address _user,
        uint256 _amount,
        uint256 _index
    ) external;

    function transferUnderlyingTo(address _target, uint256 _amount)
    external;

    function scaledBalanceOf(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "../libraries/math/WadRayMath.sol";
import "../component/vault/Vault.sol";
import "hardhat/console.sol";

contract SecurityDepositToken is ERC20, AccessControl {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    bytes32 public constant VAULT = keccak256("VAULT");

    address public underlyingAsset;
    uint8 public underlyingAssetDecimals;
    Vault public vault;

    event MintOnDeposit(address indexed account, uint256 amount);

    event BurnOnRedeem(address indexed account, uint256 amount);

    constructor(
        address _underlyingAsset,
        uint8 _underlyingAssetDecimals,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _setupRole(VAULT, msg.sender);
        vault = Vault(msg.sender);
        underlyingAsset = _underlyingAsset;
        underlyingAssetDecimals = _underlyingAssetDecimals;
    }

    function mintOnDeposit(address account, uint256 amount)
        external
        onlyRole(VAULT)
    {
        _mint(account, amount);
        emit MintOnDeposit(account, amount);
    }

    function burnOnRedeem(address account, uint256 amount)
        external
        onlyRole(VAULT)
    {
        _burn(account, amount);
        emit BurnOnRedeem(account, amount);
    }

    function underlyingBalanceOf(address _sponsor)
        external
        view
        returns (uint256)
    {
        return vault.underlyingBalance(_sponsor, underlyingAsset);
    }
}

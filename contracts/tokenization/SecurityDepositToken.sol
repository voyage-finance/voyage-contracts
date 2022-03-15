// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import '../libraries/math/WadRayMath.sol';

contract SecurityDepositToken is ERC20, AccessControl {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    bytes32 public constant VAULT = keccak256('VAULT');

    address public underlyingAsset;
    uint8 public underlyingAssetDecimals;

    event MintOnDeposit(address indexed account, uint256 amount);

    constructor(
        address _underlyingAsset,
        uint8 _underlyingAssetDecimals,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _setupRole(VAULT, msg.sender);
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
}

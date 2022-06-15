// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BaseSecurityEscrow} from "./BaseSecurityEscrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SecurityDepositEscrow is BaseSecurityEscrow {
    address public vault;

    modifier onlyOwner() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    constructor(address _vault) {
        vault = _vault;
    }

    function getVersion() external view returns (string memory) {
        string memory version = "SecurityDepositEscrow 0.0.1";
        return version;
    }

    // placeholder function
    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) public payable nonReentrant onlyOwner returns (uint256) {
        uint256 balance = IERC20(_reserve).balanceOf(address(this));
        if (balance < _amount) {
            _amount = balance;
        }
        transferToUser(_reserve, _to, _amount);
        return _amount;
    }

    function deposit(
        address _reserve,
        address _user,
        uint256 _amount
    ) public payable nonReentrant onlyOwner {
        _deposit(_reserve, _user, _amount);
    }

    function withdraw(
        address _reserve,
        address payable _user,
        uint256 _amount
    ) public onlyOwner {
        _withdraw(_reserve, _user, _amount);
    }
}

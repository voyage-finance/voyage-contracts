// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BaseMarginEscrow} from "./BaseMarginEscrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

contract MarginEscrow is BaseMarginEscrow, Initializable {
    address public vault;

    modifier onlyOwner() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    function initialize(address _vault) external initializer {
        vault = _vault;
    }

    function getVersion() external view returns (string memory) {
        string memory version = "MarginEscrow 0.0.1";
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
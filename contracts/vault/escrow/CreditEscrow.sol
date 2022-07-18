// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ICreditEscrow} from "../interfaces/ICreditEscrow.sol";
import {SafeTransferLib} from "../../shared/libraries/SafeTransferLib.sol";

contract CreditEscrow is ReentrancyGuard, Initializable, ICreditEscrow {
    using SafeTransferLib for IERC20;

    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function initialize(address _owner) external initializer {
        owner = _owner;
    }

    function transferUnderlyingTo(
        address _asset,
        address _target,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_asset).safeTransfer(_target, _amount);
    }
}

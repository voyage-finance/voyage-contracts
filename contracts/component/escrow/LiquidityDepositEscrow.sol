// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/Escrow.sol';
import 'openzeppelin-solidity/contracts/access/AccessControl.sol';

contract LiquidityDepositEscrow is Escrow, AccessControl {
    bytes32 public constant LoanManager = keccak256('LoanManager');

    //    constructor(address _loanManager) public Ownable() {
    //        _setupRole(LoanManager, _loanManager);
    //    }

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../../libraries/Escrow.sol';
import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import '../../Voyager.sol';
import '../../../interfaces/IACLManager.sol';

contract LiquidityDepositEscrow is Escrow {
    Voyager private voyager;

    modifier onlyLiquidityManager() {
        _requireCallerLiquidityManager();
        _;
    }

    modifier onlyLoanManager() {
        _requireCallerLiquidityManager();
        _;
    }

    function deposit(
        address _reserve,
        address _user,
        uint256 _amount
    ) public payable nonReentrant onlyLiquidityManager {
        _deposit(_reserve, _user, _amount);
    }

    function withdraw(
        address _reserve,
        address payable _user,
        uint256 _amount
    ) public onlyLiquidityManager {
        _withdraw(_reserve, _user, _amount);
    }

    function balanceOf(address _reserve) public view returns (uint256) {
        return IERC20(_reserve).balanceOf(address(this));
    }

    /************************************** Private Functions **************************************/

    function _requireCallerLiquidityManager() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAddress(v.getACLManagerName())
        );
        require(
            aclManager.isLiquidityManager(msg.sender),
            'Not liquidity manager'
        );
    }

    function _requireCallerLoanManager() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAddress(v.getACLManagerName())
        );
        require(aclManager.isLoanManager(msg.sender), 'Not liquidity manager');
    }
}

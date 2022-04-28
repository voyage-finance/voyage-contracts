// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../../libraries/LiquidityEscrow.sol';
import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import '../../Voyager.sol';
import '../../../interfaces/IACLManager.sol';
import '../../infra/AddressResolver.sol';

contract LiquidityDepositEscrow is LiquidityEscrow {
    Voyager private voyager;
    bool private initialized;

    modifier onlyLiquidityManager() {
        _requireCallerLiquidityManagerContract();
        _;
    }

    modifier onlyLoanManager() {
        _requireCallerLoanManagerContract();
        _;
    }

    function deposit(
        address _reserve,
        ReserveLogic.Tranche _tranche,
        address _user,
        uint256 _amount,
        uint256 _recordAmount
    ) public payable nonReentrant onlyLiquidityManager {
        _deposit(_reserve, _tranche, _user, _amount, _recordAmount);
    }

    function init(address _voyager) external {
        if (!initialized) {
            voyager = Voyager(_voyager);
            initialized = true;
        }
    }

    function withdraw(
        address _reserve,
        ReserveLogic.Tranche _tranche,
        address payable _user,
        uint256 _amount
    ) public onlyLiquidityManager {
        _withdraw(_reserve, _tranche, _user, _amount);
    }

    function transfer(
        address _reserve,
        address payable _user,
        uint256 _amount
    ) public onlyLoanManager {
        IERC20(_reserve).transfer(_user, _amount);
    }

    function balanceOf(address _reserve) public view returns (uint256) {
        return IERC20(_reserve).balanceOf(address(this));
    }

    /************************************** Private Functions **************************************/

    function _requireCallerLiquidityManagerContract() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            voyager.addressResolver().getAddress(v.getACLManagerName())
        );
        require(
            aclManager.isLiquidityManagerContract(msg.sender),
            'Not liquidity manager contract'
        );
    }

    function _requireCallerLoanManagerContract() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAddress(v.getACLManagerName())
        );
        require(
            aclManager.isLoanManagerContract(msg.sender),
            'Not loan manager contract'
        );
    }
}

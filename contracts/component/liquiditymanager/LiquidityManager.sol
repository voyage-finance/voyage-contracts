// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './ReserveManager.sol';
import '../../libraries/helpers/Errors.sol';
import '../../libraries/logic/ReserveLogic.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../shared/escrow/LiquidityDepositEscrow.sol';
import '../../interfaces/IReserveManager.sol';
import '../../interfaces/ILiquidityManager.sol';
import '../../tokenization/JuniorDepositToken.sol';
import '../../tokenization/SeniorDepositToken.sol';

contract LiquidityManager is ReserveManager, ILiquidityManager {
    LiquidityDepositEscrow public liquidityDepositEscrow;

    constructor(address payable _proxy, address _voyager)
        ReserveManager(_proxy, _voyager)
    {
        liquidityDepositEscrow = LiquidityDepositEscrow(deployEscrow());
    }

    function deployEscrow() private returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender));
        bytes memory bytecode = type(LiquidityDepositEscrow).creationCode;
        address deployedEscrow;
        assembly {
            deployedEscrow := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }
        return deployedEscrow;
    }

    function deposit(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        address _user,
        address _onBehalfOf
    ) external onlyProxy {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        DataTypes.ReserveData memory reserve = getReserveData(_asset);

        lms.updateStateOnDeposit(_asset, _tranche, _amount);

        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            JuniorDepositToken(reserve.juniorDepositTokenAddress).mint(
                _onBehalfOf,
                _amount,
                getJuniorLiquidityIndex(_asset)
            );
        } else {
            SeniorDepositToken(reserve.seniorDepositTokenAddress).mint(
                _onBehalfOf,
                _amount,
                getSeniorLiquidityIndex(_asset)
            );
        }
        liquidityDepositEscrow.deposit(_asset, _user, _amount);
        emit Deposit(_asset, _tranche, _user, _onBehalfOf, _amount);
    }

    /************************************** View Functions **************************************/

    function getEscrowAddress() external view returns (address) {
        return address(escrow());
    }

    function escrow() internal view override returns (LiquidityDepositEscrow) {
        return liquidityDepositEscrow;
    }

    function getReserveNormalizedIncome(
        address _asset,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getReserveNormalizedIncome(_asset, _tranche);
    }
}

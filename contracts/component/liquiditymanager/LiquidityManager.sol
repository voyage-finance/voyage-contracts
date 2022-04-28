// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './ReserveManager.sol';
import '../../libraries/helpers/Errors.sol';
import '../../libraries/logic/ReserveLogic.sol';
import '../../libraries/math/WadRayMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../shared/escrow/LiquidityDepositEscrow.sol';
import '../../interfaces/IReserveManager.sol';
import '../../interfaces/ILiquidityManager.sol';
import '../../tokenization/JuniorDepositToken.sol';
import '../../tokenization/SeniorDepositToken.sol';

contract LiquidityManager is ReserveManager, ILiquidityManager {
    using WadRayMath for uint256;

    LiquidityDepositEscrow public liquidityDepositEscrow;

    constructor(address payable _proxy, address _voyager)
        ReserveManager(_proxy, _voyager)
    {
        liquidityDepositEscrow = LiquidityDepositEscrow(deployEscrow());
        liquidityDepositEscrow.init(_voyager);
    }

    /************************************** User Functions **************************************/

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

        uint256 scaledBalance;

        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            JuniorDepositToken jdt = JuniorDepositToken(
                reserve.juniorDepositTokenAddress
            );
            uint256 liquidityIndex = getJuniorLiquidityIndex(_asset);
            jdt.mint(_onBehalfOf, _amount, liquidityIndex);
            scaledBalance = jdt.scaledBalanceOf(_onBehalfOf).rayDiv(
                liquidityIndex
            );
        } else {
            SeniorDepositToken sdt = SeniorDepositToken(
                reserve.seniorDepositTokenAddress
            );
            uint256 liquidityIndex = getSeniorLiquidityIndex(_asset);

            sdt.mint(_onBehalfOf, _amount, liquidityIndex);
        }
        liquidityDepositEscrow.deposit(_asset, _user, _amount, scaledBalance);
        emitDeposit(_asset, _user, _tranche, _amount);
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

    /************************************** Private Functions **************************************/

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

    /******************************************** Events *******************************************/

    function trancheToBytes32(ReserveLogic.Tranche tranche)
        public
        returns (bytes32)
    {
        return ReserveLogic.trancheToBytes32(tranche);
    }

    event Deposit(
        address indexed asset,
        address indexed user,
        uint8 indexed tranche,
        uint256 amount
    );
    bytes32 internal constant DEPOSIT_SIG =
        keccak256('Deposit(address,address,uint8,uint256)');

    function emitDeposit(
        address asset,
        address user,
        ReserveLogic.Tranche tranche,
        uint256 amount
    ) internal {
        proxy._emit(
            abi.encode(amount),
            4,
            DEPOSIT_SIG,
            addressToBytes32(asset),
            addressToBytes32(user),
            trancheToBytes32(tranche)
        );
    }
}

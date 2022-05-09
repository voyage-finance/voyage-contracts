// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import './ReserveManager.sol';
import '../../libraries/helpers/Errors.sol';
import '../../libraries/logic/ReserveLogic.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../interfaces/IReserveManager.sol';
import '../../interfaces/ILiquidityManager.sol';
import '../../tokenization/JuniorDepositToken.sol';
import '../../tokenization/SeniorDepositToken.sol';

contract LiquidityManager is
    ReserveManager,
    ILiquidityManager,
    ReentrancyGuard
{
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;

    constructor(address payable _proxy, address _voyager)
        ReserveManager(_proxy, _voyager)
    {}

    /************************************** User Functions **************************************/

    function deposit(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        address _user,
        address _onBehalfOf
    ) external payable nonReentrant onlyProxy {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        DataTypes.ReserveData memory reserve = getReserveData(_asset);

        lms.updateStateOnDeposit(_asset, _tranche, _amount);

        address vToken;
        uint256 liquidityIndex;

        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            vToken = reserve.juniorDepositTokenAddress;
            liquidityIndex = getJuniorLiquidityIndex(_asset);
        } else {
            vToken = reserve.seniorDepositTokenAddress;
            liquidityIndex = getSeniorLiquidityIndex(_asset);
        }
        IVToken(vToken).mint(_onBehalfOf, _amount, liquidityIndex);
        uint256 scaledBalance = IVToken(vToken)
            .scaledBalanceOf(_onBehalfOf)
            .rayDiv(liquidityIndex);

        if (_asset != EthAddressLib.ethAddress()) {
            require(
                msg.value == 0,
                'User is sending ETH along with the ERC20 transfer.'
            );
        } else {
            require(
                msg.value == _amount,
                'The amount and the value sent to deposit do not match'
            );
        }

        IERC20(_asset).safeTransferFrom(_user, vToken, _amount);
        emitDeposit(_asset, _user, _tranche, _amount);
    }

    function withdraw(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        address payable _user
    ) external onlyProxy {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        DataTypes.ReserveData memory reserve = getReserveData(_asset);

        address vToken;
        uint256 liquidityIndex;
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            vToken = reserve.juniorDepositTokenAddress;
            liquidityIndex = getJuniorLiquidityIndex(_asset);
        } else {
            vToken = reserve.seniorDepositTokenAddress;
            liquidityIndex = getSeniorLiquidityIndex(_asset);
        }

        uint256 userBalance = IERC20(vToken).balanceOf(_user);

        uint256 amountToWithdraw = _amount;

        if (amountToWithdraw == type(uint256).max) {
            amountToWithdraw = userBalance;
        }

        lms.updateStateOnWithdraw(_asset, _tranche, amountToWithdraw);

        IVToken(vToken).burn(_user, amountToWithdraw, liquidityIndex);
        emitWithdraw(_asset, _user, _tranche, amountToWithdraw);
    }

    /************************************** View Functions **************************************/

    function withdrawAbleAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        (uint256 scaledBalance, uint40 timestamp) = lms.eligibleAmount(
            _reserve,
            _user,
            _tranche
        );
        return
            scaledBalance.rayMul(
                LiquidityManagerStorage(liquidityManagerStorageAddress())
                    .getReserveNormalizedIncome(_reserve, _tranche)
            );
    }

    function totalDepositAndDebt() external {
        AddressResolver addressResolver = voyager.addressResolver();
        addressResolver.getStableDebtToken();
    }

    function balance(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        uint256 scaledBalance = lms.overallAmount(_reserve, _user, _tranche);
        return
            scaledBalance.rayMul(
                LiquidityManagerStorage(liquidityManagerStorageAddress())
                    .getReserveNormalizedIncome(_reserve, _tranche)
            );
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

    /******************************************** Events *******************************************/

    function trancheToBytes32(ReserveLogic.Tranche tranche)
        public
        view
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

    bytes32 internal constant WITHDRAW_SIG =
        keccak256('Withdraw(address,address,uint8,uint256)');

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

    function emitWithdraw(
        address asset,
        address user,
        ReserveLogic.Tranche tranche,
        uint256 amount
    ) internal {
        proxy._emit(
            abi.encode(amount),
            4,
            WITHDRAW_SIG,
            addressToBytes32(asset),
            addressToBytes32(user),
            trancheToBytes32(tranche)
        );
    }
}

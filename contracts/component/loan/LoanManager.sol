// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import '../../libraries/proxy/Proxyable.sol';
import '../../interfaces/IVoyagerComponent.sol';
import '../../libraries/helpers/Errors.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../libraries/types/DataTypes.sol';
import '../../interfaces/IMessageBus.sol';
import '../../interfaces/IHealthStrategy.sol';
import '../../interfaces/IInitializableDebtToken.sol';
import '../Voyager.sol';

contract LoanManager is Proxyable, IVoyagerComponent {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    LiquidityDepositEscrow public liquidityDepositEscrow;

    constructor(
        address payable _proxy,
        address _voyager,
        address _escrow
    ) Proxyable(_proxy) {
        voyager = Voyager(_voyager);
        liquidityDepositEscrow = LiquidityDepositEscrow(_escrow);
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        uint256 amount;
    }

    function borrow(
        address _user,
        address _asset,
        uint256 _amount,
        address _vault,
        uint256 _grossAssetValue
    ) external requireNotPaused {
        // 0. check if the user owns the vault
        require(voyager.getVault(_user) == _vault, Errors.LOM_NOT_VAULT_OWNER);

        // 1. check if pool liquidity is sufficient
        DataTypes.DepositAndDebt memory depositAndDebt = getDepositAndDebt();
        require(
            depositAndDebt.seniorDepositAmount - depositAndDebt.totalDebt >=
                _amount,
            Errors.LOM_RESERVE_NOT_SUFFICIENT
        );

        // 2. check HF
        DataTypes.ReserveData memory reserveData = voyager.getReserveData(
            _asset
        );
        IHealthStrategy healthStrategy = IHealthStrategy(
            reserveData.healthStrategyAddress
        );
        DataTypes.HealthRiskParameter memory hrp;
        hrp.securityDeposit = voyager.getSecurityDeposit(_user, _asset);
        hrp.currentBorrowRate = reserveData.currentBorrowRate;
        hrp.compoundedDebt = voyager.getCompoundedDebt(_user);
        hrp.grossAssetValue = _grossAssetValue;
        hrp.aggregateOptimalRepaymentRate = voyager
            .getAggregateOptimalRepaymentRate(_user);
        hrp.aggregateActualRepaymentRate = voyager
            .getAggregateActualRepaymentRate(_user);

        uint256 hr = healthStrategy.calculateHealthRisk(hrp);

        require(hr > WadRayMath.ray(), Errors.LOM_HEALTH_RISK_BELOW_ONE);

        // 3. check credit limit
        uint256 availableCreditLimit = voyager.getAvailableCredit(
            _user,
            _asset
        );
        require(
            availableCreditLimit >= _amount,
            Errors.LOM_CREDIT_NOT_SUFFICIENT
        );

        // 4. update liquidity index and interest rate
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        lms.updateStateOnBorrow(_asset, _amount);

        // 5. mint debt token and transfer underlying token
        address debtToken = voyager.addressResolver().getAddress(
            voyager.getStableDebtTokenName()
        );
        IInitializableDebtToken(debtToken).mint(
            _user,
            _amount,
            healthStrategy.getLoanTenure(),
            reserveData.currentBorrowRate
        );

        liquidityDepositEscrow.transfer(_asset, _user, _amount);
    }

    function _executeBorrow(ExecuteBorrowParams memory vars) internal {}

    function escrow() internal view override returns (LiquidityDepositEscrow) {
        return liquidityDepositEscrow;
    }
}

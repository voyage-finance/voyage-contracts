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
import '../../interfaces/IVault.sol';
import '../../interfaces/IVToken.sol';
import '../Voyager.sol';
import 'hardhat/console.sol';

contract LoanManager is Proxyable, IVoyagerComponent {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    constructor(address payable _proxy, address _voyager) Proxyable(_proxy) {
        voyager = Voyager(_voyager);
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
        address payable _vault,
        uint256 _grossAssetValue
    ) external requireNotPaused onlyProxy {
        // todo use min security deposit
        require(_amount >= 1e19, Errors.LOM_INVALID_AMOUNT);
        // 0. check if the user owns the vault
        require(voyager.getVault(_user) == _vault, Errors.LOM_NOT_VAULT_OWNER);

        // 1. check if pool liquidity is sufficient
        DataTypes.ReserveData memory reserveData = voyager.getReserveData(
            _asset
        );

        uint256 availableSeniorLiquidity = IERC20(
            reserveData.seniorDepositTokenAddress
        ).totalSupply();
        uint256 totalDebt = IERC20(reserveData.debtTokenAddress).totalSupply();
        require(
            availableSeniorLiquidity - totalDebt >= _amount,
            Errors.LOM_RESERVE_NOT_SUFFICIENT
        );

        uint256 availableJuniorLiquidity = IERC20(_asset).balanceOf(
            reserveData.juniorDepositTokenAddress
        );
        require(
            availableJuniorLiquidity >= 0,
            'invalid available junior liquidity'
        );

        // 2. check HF
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

        require(hr >= WadRayMath.ray(), Errors.LOM_HEALTH_RISK_BELOW_ONE);

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

        // 5. increase vault debt
        IVault(_vault).increaseTotalDebt(_amount);

        // 6. mint debt token and transfer underlying token
        address debtToken = voyager.addressResolver().getStableDebtToken();
        IInitializableDebtToken(debtToken).mint(
            _vault,
            _amount,
            healthStrategy.getLoanTenure(),
            reserveData.currentBorrowRate
        );

        IVToken(reserveData.seniorDepositTokenAddress).transferUnderlyingTo(
            _vault,
            _amount
        );
    }
}

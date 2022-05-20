// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../libraries/proxy/Proxyable.sol';
import '../../interfaces/IVoyagerComponent.sol';
import '../../libraries/helpers/Errors.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../libraries/types/DataTypes.sol';
import '../../interfaces/IMessageBus.sol';
import '../../interfaces/IHealthStrategy.sol';
import '../../interfaces/IStableDebtToken.sol';
import '../../interfaces/IVault.sol';
import '../../interfaces/IVToken.sol';
import '../Voyager.sol';
import 'hardhat/console.sol';

contract LoanManager is Proxyable {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;

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

        uint256 availableSeniorLiquidity = IERC20(_asset).balanceOf(
            reserveData.seniorDepositTokenAddress
        );
        uint256 totalDebt = IERC20(reserveData.debtTokenAddress).totalSupply();
        require(
            availableSeniorLiquidity - totalDebt >= _amount,
            Errors.LOM_RESERVE_NOT_SUFFICIENT
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

        // 4. mint debt token and transfer underlying token
        address debtToken = voyager.addressResolver().getStableDebtToken();
        IStableDebtToken(debtToken).mint(
            _vault,
            _amount,
            healthStrategy.getLoanTenure(),
            reserveData.currentBorrowRate
        );

        // 5. update liquidity index and interest rate
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );

        lms.updateStateOnBorrow(_asset, _amount);

        IVToken(reserveData.seniorDepositTokenAddress).transferUnderlyingTo(
            _vault,
            _amount
        );
    }

    function repay(
        address _user,
        address _asset,
        uint256 _drawDown,
        uint256 _amount,
        address payable _vault
    ) external requireNotPaused onlyProxy {
        // 0. check if the user owns the vault
        require(voyager.getVault(_user) == _vault, Errors.LOM_NOT_VAULT_OWNER);

        // 1. check if there is any outstanding debt
        address debtToken = voyager.addressResolver().getStableDebtToken();
        uint256 currentDebt = IStableDebtToken(debtToken).balanceOfDrawdown(
            address(this),
            _drawDown
        );
        require(currentDebt >= _amount, Errors.LOM_HEALTH_RISK_BELOW_ONE);

        // 2. update liquidity index and interest rate
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );

        lms.updateStateOnRepayment(_asset, _amount);

        // 3. burn debt token
        IStableDebtToken(debtToken).burn(_vault, _drawDown, _amount);

        // 4. transfer underlying asset
        DataTypes.ReserveData memory reserveData = voyager.getReserveData(
            _asset
        );

        uint256 bal = IERC20(_asset).balanceOf(
            reserveData.seniorDepositTokenAddress
        );
        IERC20(_asset).safeTransferFrom(
            _user,
            reserveData.seniorDepositTokenAddress,
            _amount
        );
    }

    function drawDowns() public {}
}

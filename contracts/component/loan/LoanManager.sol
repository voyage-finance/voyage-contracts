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
import '../../interfaces/ILoanStrategy.sol';
import '../../interfaces/IVault.sol';
import '../../interfaces/IVToken.sol';
import '../Voyager.sol';
import 'hardhat/console.sol';
import '../../interfaces/ILoanManager.sol';

contract LoanManager is Proxyable, ILoanManager {
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
        uint256 term;
        uint256 epoch;
        uint256 liquidityRate;
        uint256 borrowRate;
    }

    function borrow(
        address _user,
        address _asset,
        uint256 _amount,
        address payable _vault,
        uint256 _grossAssetValue
    ) external requireNotPaused onlyProxy {
        ExecuteBorrowParams memory executeBorrowParams;
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
        require(
            availableSeniorLiquidity >= _amount,
            Errors.LOM_RESERVE_NOT_SUFFICIENT
        );

        // 2. check HF
        //        IHealthStrategy healthStrategy = IHealthStrategy(
        //            reserveData.healthStrategyAddress
        //        );

        // 3. check credit limit
        uint256 availableCreditLimit = voyager.getAvailableCredit(
            _user,
            _asset
        );

        require(
            availableCreditLimit >= _amount,
            Errors.LOM_CREDIT_NOT_SUFFICIENT
        );

        // 4. update debt logic
        executeBorrowParams.term = ILoanStrategy(
            reserveData.loanStrategyAddress
        ).getTerm();
        executeBorrowParams.epoch = ILoanStrategy(
            reserveData.loanStrategyAddress
        ).getEpoch();

        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );

        // 5. update liquidity index and interest rate
        DataTypes.BorrowStat memory borrowStat = lms.getBorrowStat(_asset);
        (
            executeBorrowParams.liquidityRate,
            executeBorrowParams.borrowRate
        ) = IReserveInterestRateStrategy(
            reserveData.interestRateStrategyAddress
        ).calculateInterestRates(
                _asset,
                reserveData.seniorDepositTokenAddress,
                0,
                _amount,
                borrowStat.totalDebt,
                borrowStat.avgBorrowRate
            );
        lms.updateStateOnBorrow(
            _asset,
            _amount,
            borrowStat.totalDebt.add(borrowStat.totalInterest),
            executeBorrowParams.borrowRate
        );

        lms.insertDebt(
            _asset,
            _vault,
            _amount,
            executeBorrowParams.term,
            executeBorrowParams.epoch,
            executeBorrowParams.borrowRate
        );

        IVToken(reserveData.seniorDepositTokenAddress).transferUnderlyingTo(
            _vault,
            _amount
        );
    }

    function repay(
        address _user,
        address _asset,
        uint256 _drawDown,
        address payable _vault
    ) external requireNotPaused onlyProxy {
        // 0. check if the user owns the vault
        require(voyager.getVault(_user) == _vault, Errors.LOM_NOT_VAULT_OWNER);

        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );

        // 1. check draw down to get principal and interest
        uint256 principal;
        uint256 interest;
        (principal, interest) = lms.getPMT(_asset, _vault, _drawDown);
        require(principal.add(interest) != 0, Errors.LOM_INVALID_DEBT);

        // 2. update liquidity index and interest rate
        DataTypes.BorrowStat memory borrowStat = lms.getBorrowStat(_asset);
        uint256 totalDebt = borrowStat.totalDebt.add(borrowStat.totalInterest);
        uint256 avgBorrowRate = borrowStat.avgBorrowRate;
        lms.updateStateOnRepayment(
            _asset,
            principal.add(interest),
            totalDebt,
            avgBorrowRate
        );

        // 3. update repay data
        lms.repay(_asset, _vault, _drawDown, principal, interest);

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
            principal.add(interest)
        );
    }

    function getVaultDebt(address _reserve, address _vault)
        external
        view
        returns (uint256, uint256)
    {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        return lms.getVaultDebt(_reserve, _vault);
    }

    function getDrawDownList(address _reserve, address _vault)
        external
        view
        returns (uint256, uint256)
    {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        return lms.getDrawDownList(_reserve, _vault);
    }

    function getDrawDownDetail(
        address _reserve,
        address _vault,
        uint256 _drawDownId
    ) external view returns (DataTypes.DebtDetail memory) {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        return lms.getDrawDownDetail(_reserve, _vault, _drawDownId);
    }
}

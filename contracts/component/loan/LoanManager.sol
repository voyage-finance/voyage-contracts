// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LiquidityManagerStorage} from "../../component/shared/storage/LiquidityManagerStorage.sol";
import {Proxyable} from "../../libraries/proxy/Proxyable.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {IVoyagerComponent} from "../../interfaces/IVoyagerComponent.sol";
import {IMessageBus} from "../../interfaces/IMessageBus.sol";
import {IHealthStrategy} from "../../interfaces/IHealthStrategy.sol";
import {IReserveInterestRateStrategy} from "../../interfaces/IReserveInterestRateStrategy.sol";
import {ILoanStrategy} from "../../interfaces/ILoanStrategy.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IVToken} from "../../interfaces/IVToken.sol";
import {ILoanManager} from "../../interfaces/ILoanManager.sol";
import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {Voyager} from "../Voyager.sol";
import {ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";

contract LoanManager is Proxyable, ILoanManager {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;

    constructor(address payable _proxy, address payable _voyager)
        Proxyable(_proxy)
    {
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

    struct ExecuteLiquidateParams {
        address reserve;
        address vault;
        uint256 drawDownId;
        uint256 principal;
        uint256 interest;
        uint256 totalDebt;
        uint256 totalFromMargin;
        uint256 totalToLiquidate;
        uint256 discount;
        uint256 totalSlash;
        address liquidator;
        uint256 floorPrice;
        uint256 totalNFTNums;
        uint256 numNFTsToLiquidate;
        uint256 gracePeriod;
        uint256 liquidationBonus;
        uint256 marginRequirement;
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
        lms.repay(_asset, _vault, _drawDown, principal, interest, false);

        // 4. transfer underlying asset
        DataTypes.ReserveData memory reserveData = voyager.getReserveData(
            _asset
        );

        IERC20(_asset).safeTransferFrom(
            _user,
            reserveData.seniorDepositTokenAddress,
            principal.add(interest)
        );
    }

    function liquidate(
        address _liquidator,
        address _reserve,
        address _vault,
        uint256 _drawDownId
    ) external requireNotPaused onlyProxy {
        ExecuteLiquidateParams memory param;
        DataTypes.ReserveData memory reserveData = voyager.getReserveData(
            param.reserve
        );
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );

        // 1. prepare basic info and some strategy parameters
        param.reserve = _reserve;
        param.vault = _vault;
        param.drawDownId = _drawDownId;
        param.liquidator = _liquidator;
        (
            param.gracePeriod,
            param.liquidationBonus,
            param.marginRequirement
        ) = ILoanStrategy(reserveData.loanStrategyAddress)
            .getLiquidationParams();
        param.totalNFTNums = IVault(param.vault).getTotalNFTNumbers(
            reserveData.nftAddress
        );

        DataTypes.DebtDetail memory debtDetail = lms.getDrawDownDetail(
            param.reserve,
            param.vault,
            param.drawDownId
        );

        // 2. check if the debt is qualified to be liquidated
        require(
            block.timestamp.sub(debtDetail.nextPaymentDue) > param.gracePeriod,
            Errors.LOM_INVALID_LIQUIDATE
        );

        // 3.1 if it is, get debt info
        (param.principal, param.interest) = lms.getPMT(
            param.reserve,
            param.vault,
            param.drawDownId
        );
        param.totalDebt = param.principal.add(param.interest);
        param.totalFromMargin = param
            .totalDebt
            .wadToRay()
            .rayMul(param.marginRequirement)
            .rayToWad();
        param.totalToLiquidate = param.totalDebt.sub(param.totalFromMargin);
        param.discount = getDiscount(
            param.totalToLiquidate,
            param.liquidationBonus
        );

        // 3.2 get floor price from oracle contract
        param.floorPrice = IPriceOracle(getPriceOracleAddress()).getAssetPrice(
            reserveData.nftAddress
        );

        param.numNFTsToLiquidate = param
            .totalToLiquidate
            .sub(param.discount)
            .div(param.floorPrice);
        param.totalSlash = param.totalFromMargin.add(param.discount);

        // 4.1 slash margin account
        uint256 amountSlashed = IVault(param.vault).slash(
            param.reserve,
            payable(address(this)),
            param.totalSlash
        );

        uint256 amountNeedExtra = param.totalSlash.sub(amountSlashed);

        // 4.2 transfer from liquidator
        IERC20(param.reserve).safeTransferFrom(
            param.liquidator,
            address(this),
            param.totalToLiquidate
        );

        if (param.totalNFTNums < param.numNFTsToLiquidate) {
            uint256 missingNFTNums = param.numNFTsToLiquidate.sub(
                param.totalNFTNums
            );
            amountNeedExtra = missingNFTNums.mul(param.floorPrice).add(
                amountNeedExtra
            );
            param.numNFTsToLiquidate = param.totalNFTNums;
        }

        // 4.3 sell nft
        IVault(param.vault).transferNFT(
            reserveData.nftAddress,
            param.liquidator,
            param.numNFTsToLiquidate
        );

        // 4.4 transfer from junior tranche
        uint256 totalAssetFromJuniorTranche = ERC4626(
            reserveData.juniorDepositTokenAddress
        ).totalAssets();

        if (totalAssetFromJuniorTranche >= amountNeedExtra) {
            IVToken(reserveData.juniorDepositTokenAddress).transferUnderlyingTo(
                    address(this),
                    amountNeedExtra
                );
        } else {
            IVToken(reserveData.juniorDepositTokenAddress).transferUnderlyingTo(
                    address(this),
                    totalAssetFromJuniorTranche
                );

            uint256 amountToWriteDown = amountNeedExtra.sub(
                totalAssetFromJuniorTranche
            );
            // todo write down to somewhere
        }

        lms.repay(
            param.reserve,
            param.vault,
            param.drawDownId,
            param.principal,
            param.interest,
            true
        );

        IERC20(param.reserve).safeTransfer(
            reserveData.seniorDepositTokenAddress,
            param.totalDebt
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

    /// @notice Returns the total outstanding principal debt for a particular underlying asset pool
    /// @param underlyingAsset the address of the underlying reserve asset
    /// @return The total outstanding principal owed to depositors.
    function principalBalance(address underlyingAsset)
        external
        view
        returns (uint256)
    {
        DataTypes.BorrowStat memory borrowState = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        ).getBorrowStat(underlyingAsset);
        return borrowState.totalDebt;
    }

    /// @notice Returns the total outstanding interest debt for a particular underlying asset pool
    /// @param underlyingAsset the address of the underlying reserve asset
    /// @return The total outstanding interest owed to depositors.
    function interestBalance(address underlyingAsset)
        external
        view
        returns (uint256)
    {
        DataTypes.BorrowStat memory borrowState = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        ).getBorrowStat(underlyingAsset);
        return borrowState.totalInterest;
    }

    function getDiscount(uint256 _value, uint256 _liquidationBonus)
        private
        view
        returns (uint256)
    {
        uint256 valueInRay = _value.wadToRay();
        uint256 discountValueInRay = valueInRay.rayMul(_liquidationBonus);
        return discountValueInRay.rayToWad();
    }
}

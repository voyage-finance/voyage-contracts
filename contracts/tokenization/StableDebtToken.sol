// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/math/WadRayMath.sol';
import '../libraries/math/MathUtils.sol';
import '../component/infra/AddressResolver.sol';
import './DebtTokenBase.sol';
import '../interfaces/IDebtToken.sol';
import '../libraries/types/DataTypes.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeCast.sol';
import 'openzeppelin-solidity/contracts/utils/Context.sol';
import '../libraries/helpers/Errors.sol';
import '../interfaces/IInitializableDebtToken.sol';
import 'hardhat/console.sol';

contract StableDebtToken is
    Context,
    IInitializableDebtToken,
    IStableDebtToken,
    DebtTokenBase
{
    using WadRayMath for uint256;
    using SafeCast for uint256;

    modifier onlyLoanManager() {
        require(
            _msgSender() == addressResolver.getLoanManager(),
            Errors.CT_CALLER_MUST_BE_LOAN_MANAGER
        );
        _;
    }

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;
    uint256 public constant SECONDS_PER_DAY = 1 days;

    uint256 internal _avgStableRate;
    mapping(address => uint256) internal _usersStableRate;
    uint40 internal _totalSupplyTimestamp;
    mapping(address => DataTypes.BorrowData) internal _borrowData;

    AddressResolver internal addressResolver;
    address internal underlyingAsset;

    function initialize(
        address _underlyingAsset,
        uint8 _debtTokenDecimals,
        string memory _debtTokenName,
        string memory _debtTokenSymbol,
        address _addressResolver,
        bytes calldata _params
    ) external initializer {
        _setName(_debtTokenName);
        _setSymbol(_debtTokenSymbol);
        _setDecimals(_debtTokenDecimals);

        underlyingAsset = _underlyingAsset;
        addressResolver = AddressResolver(_addressResolver);

        emit Initialized(
            underlyingAsset,
            _debtTokenDecimals,
            _debtTokenName,
            _debtTokenSymbol,
            _params
        );
    }

    /**
     * @dev Returns the average stable rate
     **/
    function getAverageStableRate() external view override returns (uint256) {
        return _avgStableRate;
    }

    /**
     * @dev Calculate the current user debt principal
     **/
    function principalOf(address _account) public view returns (uint256) {
        DataTypes.BorrowData storage borrowData = _borrowData[_account];
        uint256 principal;
        for (uint256 i = 0; i < borrowData.drawDownNumber; i++) {
            principal += borrowData.drawDowns[i].amount;
        }

        return principal;
    }

    /**
     * @dev Calculates the current user debt balance
     * @return The accumulated debt of the user
     **/
    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        DataTypes.BorrowData storage borrowData = _borrowData[_account];
        uint256 cumulatedBalance;
        for (uint256 i = 0; i < borrowData.drawDownNumber; i++) {
            uint256 stableRate = borrowData.drawDowns[i].borrowRate;
            uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
                stableRate,
                borrowData.drawDowns[i].timestamp
            );
            cumulatedBalance += borrowData.drawDowns[i].amount.rayMul(
                cumulatedInterest
            );
        }
        return cumulatedBalance;
    }

    function _mint(address _account) internal {
        DataTypes.BorrowData storage borrowData = _borrowData[_account];
        for (uint256 i = 0; i < borrowData.drawDownNumber; i++) {
            DataTypes.DrawDown storage drawDown = borrowData.drawDowns[i];
            uint256 stableRate = drawDown.borrowRate;
            uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
                stableRate,
                drawDown.timestamp
            );
            drawDown.amount = drawDown.amount.rayMul(cumulatedInterest);
            drawDown.timestamp = uint40(block.timestamp);
        }
    }

    /**
     * @dev Returns the the total supply and the average stable rate
     **/
    function getTotalSupplyAndAvgRate()
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 avgRate = _avgStableRate;
        return (_calcTotalSupply(avgRate), avgRate);
    }

    /**
     * @dev Calculates the total supply
     * @param avgRate The average rate at which the total supply increases
     * @return The debt balance of the user since the last burn/mint action
     **/
    function _calcTotalSupply(uint256 avgRate)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 principalSupply = super.totalSupply();

        if (principalSupply == 0) {
            return 0;
        }

        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            avgRate,
            _totalSupplyTimestamp
        );

        return principalSupply.rayMul(cumulatedInterest);
    }

    function _getUnderlyingAssetAddress()
        internal
        view
        override
        returns (address)
    {
        return underlyingAsset;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return DEBT_TOKEN_REVISION;
    }

    function getAggregateOptimalRepaymentRate(address _user)
        external
        view
        returns (uint256)
    {
        DataTypes.BorrowData storage bd = _borrowData[_user];
        uint256 stableRate = _usersStableRate[_user];
        uint256 aggregateOptimalRepaymentRate;
        for (uint256 i = 0; i < bd.drawDownNumber; i++) {
            DataTypes.DrawDown storage drawDone = bd.drawDowns[i];
            uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
                stableRate,
                drawDone.timestamp
            );
            uint256 cumulatedBalance = drawDone.amount.rayMul(
                cumulatedInterest
            );
            aggregateOptimalRepaymentRate += cumulatedBalance.rayDiv(
                drawDone.tenure.rayMul(SECONDS_PER_DAY * WadRayMath.ray())
            );
        }
        return aggregateOptimalRepaymentRate;
    }

    function getAggregateActualRepaymentRate(address _user)
        external
        view
        returns (uint256)
    {
        DataTypes.BorrowData storage bd = _borrowData[_user];
        uint256 aggregateActualRepayment;
        for (uint256 i = 0; i < bd.drawDownNumber; i++) {
            DataTypes.DrawDown storage drawDone = bd.drawDowns[i];
            DataTypes.Repayment storage repayment = drawDone.repayment;
            if (
                repayment.totalPaid != 0 && block.timestamp > drawDone.timestamp
            ) {
                aggregateActualRepayment += repayment.totalPaid.rayDiv(
                    (block.timestamp - drawDone.timestamp) * WadRayMath.ray()
                );
            }
        }
        return aggregateActualRepayment;
    }

    struct MintLocalVars {
        uint256 previousSupply;
        uint256 nextSupply;
        uint256 amountInRay;
        uint256 currentStableRate;
        uint256 nextStableRate;
        uint256 currentAvgStableRate;
    }

    function mint(
        address _user,
        uint256 _amount,
        uint256 _tenure,
        uint256 _rate
    ) external override onlyLoanManager {
        MintLocalVars memory vars;

        (
            ,
            uint256 currentBalance,
            uint256 balanceIncrease
        ) = _calculateBalanceIncrease(_user);

        vars.previousSupply = totalSupply();
        vars.currentAvgStableRate = _avgStableRate;
        vars.nextSupply = _totalSupply = vars.previousSupply + _amount;

        vars.amountInRay = _amount.wadToRay();
        vars.currentStableRate = _usersStableRate[_user];

        DataTypes.BorrowData storage bd = _borrowData[_user];
        uint256 currentDrawDownNumber = bd.drawDownNumber;
        bd.drawDowns[currentDrawDownNumber].amount = _amount;
        bd.drawDowns[currentDrawDownNumber].tenure = _tenure;
        bd.drawDowns[currentDrawDownNumber].borrowRate = _rate;
        bd.drawDowns[currentDrawDownNumber].timestamp = uint40(block.timestamp);
        bd.drawDownNumber++;

        vars.nextStableRate = (vars.currentStableRate.rayMul(
            currentBalance.wadToRay()
        ) + vars.amountInRay.rayMul(_rate)).rayDiv(
                (currentBalance + _amount).wadToRay()
            );

        _usersStableRate[_user] = vars.nextStableRate.toUint128();

        _totalSupplyTimestamp = uint40(block.timestamp);

        // Calculates the updated average stable rate
        vars.currentAvgStableRate = _avgStableRate = (
            (vars.currentAvgStableRate.rayMul(vars.previousSupply.wadToRay()) +
                _rate.rayMul(vars.amountInRay)).rayDiv(
                    vars.nextSupply.wadToRay()
                )
        ).toUint128();
        _mint(_user);
        emit Mint(
            _user,
            _amount,
            currentBalance,
            balanceIncrease,
            vars.nextStableRate,
            vars.currentAvgStableRate,
            vars.nextSupply
        );
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _calcTotalSupply(_avgStableRate);
    }

    function getTotalSupplyLastUpdated() external view returns (uint40) {
        return _totalSupplyTimestamp;
    }

    function underlyingAssetAddress() external view returns (address) {
        return underlyingAsset;
    }

    /**
     * @dev Calculates the increase in balance since the last user interaction
     * @param _user The address of the user for which the
     * @return The previous principal balance
     * @return The new principal balance
     * @return The balance increase
     **/
    function _calculateBalanceIncrease(address _user)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 principal = principalOf(_user);
        if (principal == 0) {
            return (0, 0, 0);
        }

        uint256 newPrincipalBalance = balanceOf(_user);
        return (
            principal,
            newPrincipalBalance,
            newPrincipalBalance - principal
        );
    }
}

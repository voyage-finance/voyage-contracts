// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/math/WadRayMath.sol';
import '../libraries/math/MathUtils.sol';
import '../component/infra/AddressResolver.sol';
import './BaseERC20.sol';
import '../interfaces/IStableDebtToken.sol';
import '../libraries/types/DataTypes.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeCast.sol';
import 'openzeppelin-solidity/contracts/utils/Context.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import '../libraries/helpers/Errors.sol';
import './base/InitializableToken.sol';
import 'hardhat/console.sol';

contract StableDebtToken is
    Context,
    InitializableToken,
    IStableDebtToken,
    BaseERC20('DEBTTOKEN_IMPL', 'DEBTTOKEN_IMPL', 0)
{
    using WadRayMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;

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
    mapping(address => uint256) internal _vaultRate;
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
     * @dev Calculate the current vault debt principal
     **/
    function principalOf(address _vaultAddr) public view returns (uint256) {
        DataTypes.BorrowData storage borrowData = _borrowData[_vaultAddr];
        return borrowData.totalDebt;
    }

    function drawDoneNumber(address _vaultAddr) public view returns (uint256) {
        return _borrowData[_vaultAddr].drawDownNumber;
    }

    function drawDown(address _vaultAddr, uint256 _drawDownNumber)
        public
        view
        returns (DataTypes.DebtDetail memory)
    {
        DataTypes.DrawDown storage drawDown = _borrowData[_vaultAddr].drawDowns[
            _drawDownNumber
        ];
        DataTypes.DebtDetail memory debtDetail;
        debtDetail.amount = drawDown.amount;
        debtDetail.timestamp = drawDown.timestamp;
        debtDetail.tenure = drawDown.tenure;
        debtDetail.borrowRate = drawDown.borrowRate;
        return debtDetail;
    }

    function repaymentOverall(address _vaultAddr, uint256 _drawDownNumber)
        public
        view
        returns (DataTypes.RepaymentDetail memory)
    {
        DataTypes.DrawDown storage drawDown = _borrowData[_vaultAddr].drawDowns[
            _drawDownNumber
        ];
        DataTypes.RepaymentDetail memory repaymentDetail;
        repaymentDetail.totalPaid = drawDown.repayment.totalPaid;
        repaymentDetail.numPayments = drawDown.repayment.numPayments;
        return repaymentDetail;
    }

    function repaymentHistory(
        address _vaultAddr,
        uint256 _drawDownNumber,
        uint256 _tenure
    ) public view returns (uint256) {
        DataTypes.DrawDown storage drawDown = _borrowData[_vaultAddr].drawDowns[
            _drawDownNumber
        ];

        return drawDown.repayment.payments[_drawDownNumber];
    }

    /**
     * @dev Calculates the current vault debt balance
     * @return The accumulated debt of the vault
     **/
    function balanceOf(address _vaultAddr)
        public
        view
        override
        returns (uint256)
    {
        DataTypes.BorrowData storage borrowData = _borrowData[_vaultAddr];
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

    function balanceOfDrawdown(address _vaultAddr, uint256 _drawDown)
        external
        view
        returns (uint256)
    {
        DataTypes.BorrowData storage borrowData = _borrowData[_vaultAddr];
        uint256 cumulatedBalance;
        uint256 stableRate = borrowData.drawDowns[_drawDown].borrowRate;
        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            stableRate,
            borrowData.drawDowns[_drawDown].timestamp
        );
        cumulatedBalance += borrowData.drawDowns[_drawDown].amount.rayMul(
            cumulatedInterest
        );
        return cumulatedInterest;
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

    function getAggregateOptimalRepaymentRate(address _vaultAddr)
        external
        view
        returns (uint256)
    {
        DataTypes.BorrowData storage bd = _borrowData[_vaultAddr];
        uint256 stableRate = _vaultRate[_vaultAddr];
        uint256 aggregateOptimalRepaymentRate;
        for (uint256 i = 0; i < bd.drawDownNumber; i++) {
            DataTypes.DrawDown storage drawDone = bd.drawDowns[i];
            uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
                stableRate,
                drawDone.timestamp
            );
            uint256 remainingBalance = drawDone.amount -
                drawDone.repayment.totalPaid;
            uint256 cumulatedBalance = remainingBalance.rayMul(
                cumulatedInterest
            );
            aggregateOptimalRepaymentRate += cumulatedBalance.rayDiv(
                drawDone.tenure.rayMul(SECONDS_PER_DAY * WadRayMath.ray())
            );
        }
        return aggregateOptimalRepaymentRate;
    }

    function getAggregateActualRepaymentRate(address _vaultAddr)
        external
        view
        returns (uint256)
    {
        DataTypes.BorrowData storage bd = _borrowData[_vaultAddr];
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
        address _vaultAddr,
        uint256 _amount,
        uint256 _tenure,
        uint256 _rate
    ) external override onlyLoanManager {
        MintLocalVars memory vars;

        (
            ,
            uint256 currentBalance,
            uint256 balanceIncrease
        ) = _calculateBalanceIncrease(_vaultAddr);

        vars.previousSupply = totalSupply();
        vars.currentAvgStableRate = _avgStableRate;
        vars.nextSupply = _totalSupply = vars.previousSupply + _amount;

        vars.amountInRay = _amount.wadToRay();
        vars.currentStableRate = _vaultRate[_vaultAddr];

        DataTypes.BorrowData storage bd = _borrowData[_vaultAddr];
        uint256 currentDrawDownNumber = bd.drawDownNumber;
        bd.drawDowns[currentDrawDownNumber].amount = _amount;
        bd.drawDowns[currentDrawDownNumber].tenure = _tenure;
        bd.drawDowns[currentDrawDownNumber].borrowRate = _rate;
        bd.drawDowns[currentDrawDownNumber].timestamp = uint40(block.timestamp);
        bd.mapSize++;
        bd.drawDownNumber++;
        bd.totalDebt += _amount;

        vars.nextStableRate = (vars.currentStableRate.rayMul(
            currentBalance.wadToRay()
        ) + vars.amountInRay.rayMul(_rate)).rayDiv(
                (currentBalance + _amount).wadToRay()
            );

        _vaultRate[_vaultAddr] = vars.nextStableRate.toUint128();

        _totalSupplyTimestamp = uint40(block.timestamp);

        // Calculates the updated average stable rate
        vars.currentAvgStableRate = _avgStableRate = (
            (vars.currentAvgStableRate.rayMul(vars.previousSupply.wadToRay()) +
                _rate.rayMul(vars.amountInRay)).rayDiv(
                    vars.nextSupply.wadToRay()
                )
        ).toUint128();
        _update(_vaultAddr);
        emit Mint(
            _vaultAddr,
            _amount,
            currentBalance,
            balanceIncrease,
            vars.nextStableRate,
            vars.currentAvgStableRate,
            vars.nextSupply
        );
    }

    function burn(
        address _vaultAddr,
        uint256 _drawDown,
        uint256 _amount
    ) external override onlyLoanManager {
        uint256 previousSupply = totalSupply();
        uint256 newAvgStableRate = 0;
        uint256 nextSupply = 0;
        uint256 vaultRate = _vaultRate[_vaultAddr];

        if (previousSupply <= _amount) {
            _avgStableRate = 0;
            _totalSupply = 0;
        } else {
            nextSupply = _totalSupply = previousSupply.sub(_amount);
            // refer to aave protocol v2
            uint256 firstTerm = _avgStableRate.rayMul(
                previousSupply.wadToRay()
            );
            uint256 secondTerm = vaultRate.rayMul(_amount.wadToRay());
            if (secondTerm >= firstTerm) {
                newAvgStableRate = _avgStableRate = _totalSupply = 0;
            } else {
                newAvgStableRate = _avgStableRate = firstTerm
                    .sub(secondTerm)
                    .rayDiv(nextSupply.wadToRay());
            }
        }
        _update(_vaultAddr);
        DataTypes.BorrowData storage bd = _borrowData[_vaultAddr];
        DataTypes.DrawDown storage drawDown = bd.drawDowns[_drawDown];

        // update amount and timestamp
        drawDown.amount -= _amount;
        drawDown.timestamp = uint40(block.timestamp);
        bd.totalDebt -= _amount;

        // clean up date if necessary
        if (drawDown.amount == 0) {
            delete _borrowData[_vaultAddr].drawDowns[_drawDown];
            _borrowData[_vaultAddr].mapSize--;
            if (_borrowData[_vaultAddr].mapSize == 0) {
                delete _vaultRate[_vaultAddr];
                delete _borrowData[_vaultAddr];
            }
        } else {
            // update repayment
            uint256 numPayment = drawDown.repayment.numPayments;
            drawDown.repayment.payments[numPayment] = _amount;
            drawDown.repayment.totalPaid += _amount;
            drawDown.repayment.numPayments++;
        }
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

    /************************************** Private Functions **************************************/

    function _update(address _account) internal {
        DataTypes.BorrowData storage borrowData = _borrowData[_account];
        for (uint256 i = 0; i < borrowData.drawDownNumber; i++) {
            DataTypes.DrawDown storage drawDown = borrowData.drawDowns[i];
            uint256 stableRate = drawDown.borrowRate;
            uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
                stableRate,
                drawDown.timestamp
            );
            uint256 cumulatedBalance = drawDown.amount.rayMul(
                cumulatedInterest
            );
            uint256 balanceIncreased = cumulatedInterest - drawDown.amount;
            drawDown.amount = cumulatedBalance;
            drawDown.timestamp = uint40(block.timestamp);
            borrowData.totalDebt += balanceIncreased;
        }
    }

    /**
     * @dev Calculates the increase in balance since the last user interaction
     * @param _vaultAddr The address of the value address
     * @return The previous principal balance
     * @return The new principal balance
     * @return The balance increase
     **/
    function _calculateBalanceIncrease(address _vaultAddr)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 principal = principalOf(_vaultAddr);
        if (principal == 0) {
            return (0, 0, 0);
        }

        uint256 newPrincipalBalance = balanceOf(_vaultAddr);
        return (
            principal,
            newPrincipalBalance,
            newPrincipalBalance - principal
        );
    }

    function _getUnderlyingAssetAddress() internal view returns (address) {
        return underlyingAsset;
    }

    /**
     * @dev Calculates the total supply
     * @param avgRate The average rate at which the total supply increases
     * @return The debt balance of the vault since the last burn/mint action
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

    function getRevision() internal pure virtual override returns (uint256) {
        return DEBT_TOKEN_REVISION;
    }

    /**
     * @dev Being non transferrable, the debt token does not implement any of the
     * standard ERC20 functions for transfer and allowance.
     **/
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        recipient;
        amount;
        revert('TRANSFER_NOT_SUPPORTED');
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        owner;
        spender;
        revert('ALLOWANCE_NOT_SUPPORTED');
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        amount;
        revert('APPROVAL_NOT_SUPPORTED');
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        sender;
        recipient;
        amount;
        revert('TRANSFER_NOT_SUPPORTED');
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        addedValue;
        revert('ALLOWANCE_NOT_SUPPORTED');
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        returns (bool)
    {
        spender;
        subtractedValue;
        revert('ALLOWANCE_NOT_SUPPORTED');
    }
}

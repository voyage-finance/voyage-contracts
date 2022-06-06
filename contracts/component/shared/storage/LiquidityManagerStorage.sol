// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../../libraries/state/State.sol';
import '../../../libraries/types/DataTypes.sol';
import '../../../libraries/logic/ReserveLogic.sol';
import '../../../libraries/logic/DebtLogic.sol';
import '../../../libraries/logic/ValidationLogic.sol';
import '../../../libraries/configuration/ReserveConfiguration.sol';
import '../../../libraries/math/WadRayMath.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';

contract LiquidityManagerStorage is State {
    using ReserveLogic for DataTypes.ReserveData;
    using DebtLogic for DataTypes.BorrowData;
    using DebtLogic for DataTypes.BorrowStat;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeMath for uint256;
    using WadRayMath for uint256;

    mapping(address => DataTypes.ReserveData) internal _reserves;

    // asset => vault address => borrow data
    mapping(address => mapping(address => DataTypes.BorrowData))
        internal _borrowData;

    mapping(address => DataTypes.BorrowStat) internal _borrowStat;

    // List of reserves as a map (reserveId => reserve)
    mapping(uint256 => address) internal _reserveList;

    // Maximum number of active reserves there have been in the protocol. It is the upper bound of the reserves list
    uint16 internal _reservesCount;

    bool internal _paused;

    constructor(address _liquidityManager) State(_liquidityManager) {}

    function insertDebt(
        address _reserve,
        address _vault,
        uint256 _principal,
        uint256 _term,
        uint256 _epoch,
        uint256 _apr
    ) external onlyAssociatedContract {
        _borrowData[_reserve][_vault].insertDrawDown(
            _borrowStat[_reserve],
            _principal,
            _term,
            _epoch,
            _apr
        );
    }

    function repay(
        address _reserve,
        address _vault,
        uint256 _drawDownNumber,
        uint256 _principal,
        uint256 _interest
    ) external onlyAssociatedContract {
        _borrowData[_reserve][_vault].repay(
            _borrowStat[_reserve],
            _drawDownNumber,
            _principal,
            _interest
        );
    }

    function initReserve(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress,
        address _loanStrategyAddress,
        uint256 _optimalIncomeRatio
    ) external onlyAssociatedContract {
        _reserves[_asset].init(
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _interestRateStrategyAddress,
            _healthStrategyAddress,
            _loanStrategyAddress,
            _optimalIncomeRatio
        );

        _reserveList[_reservesCount] = _asset;
        _reservesCount++;
    }

    function updateStateOnDeposit(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) public onlyAssociatedContract {
        DataTypes.ReserveData storage reserve = _reserves[_asset];
        ValidationLogic.validateDeposit(reserve, _amount);
        reserve.updateState(_tranche);
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            reserve.updateInterestRates(
                _asset,
                reserve.juniorDepositTokenAddress,
                reserve.seniorDepositTokenAddress,
                _amount,
                0,
                0,
                0,
                _totalDebt,
                _avgBorrowRate
            );
        } else {
            reserve.updateInterestRates(
                _asset,
                reserve.juniorDepositTokenAddress,
                reserve.seniorDepositTokenAddress,
                0,
                0,
                _amount,
                0,
                _totalDebt,
                _avgBorrowRate
            );
        }
    }

    function updateStateOnWithdraw(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) public onlyAssociatedContract {
        DataTypes.ReserveData storage reserve = _reserves[_asset];
        reserve.updateState(_tranche);
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            reserve.updateInterestRates(
                _asset,
                reserve.juniorDepositTokenAddress,
                reserve.seniorDepositTokenAddress,
                0,
                _amount,
                0,
                0,
                _totalDebt,
                _avgBorrowRate
            );
        } else {
            reserve.updateInterestRates(
                _asset,
                reserve.juniorDepositTokenAddress,
                reserve.seniorDepositTokenAddress,
                0,
                0,
                0,
                0,
                _totalDebt,
                _avgBorrowRate
            );
        }
    }

    function updateStateOnBorrow(
        address _asset,
        uint256 _amount,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) public onlyAssociatedContract {
        DataTypes.ReserveData storage reserve = _reserves[_asset];
        reserve.updateState(ReserveLogic.Tranche.SENIOR);
        reserve.updateInterestRates(
            _asset,
            reserve.juniorDepositTokenAddress,
            reserve.seniorDepositTokenAddress,
            0,
            0,
            0,
            _amount,
            _totalDebt,
            _avgBorrowRate
        );
    }

    function updateStateOnRepayment(
        address _asset,
        uint256 _amount,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) public onlyAssociatedContract {
        DataTypes.ReserveData storage reserve = _reserves[_asset];
        reserve.updateState(ReserveLogic.Tranche.SENIOR);
        reserve.updateInterestRates(
            _asset,
            reserve.juniorDepositTokenAddress,
            reserve.seniorDepositTokenAddress,
            0,
            0,
            _amount,
            0,
            _totalDebt,
            _avgBorrowRate
        );
    }

    function activeReserve(address _asset) public onlyAssociatedContract {
        DataTypes.ReserveConfigurationMap
            memory currentConfig = getConfiguration(_asset);
        currentConfig.setActive(true);
        setConfiguration(_asset, currentConfig.data);
    }

    function pause() public onlyAssociatedContract {
        _paused = true;
    }

    function unPause() public onlyAssociatedContract {
        _paused = false;
    }

    /*********************************************** View functions ***********************************************/

    function getFlags(address _asset)
        public
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        DataTypes.ReserveConfigurationMap
            memory currentConfig = getConfiguration(_asset);
        return currentConfig.getFlags();
    }

    function getReserveData(address _asset)
        public
        view
        returns (DataTypes.ReserveData memory)
    {
        return _reserves[_asset];
    }

    function getReserveList() public view returns (address[] memory) {
        address[] memory reserveList = new address[](_reservesCount);
        for (uint256 i = 0; i < _reservesCount; i++) {
            reserveList[i] = _reserveList[i];
        }
        return reserveList;
    }

    function getConfiguration(address _asset)
        public
        view
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        return _reserves[_asset].configuration;
    }

    function setConfiguration(address _asset, uint256 configuration) internal {
        _reserves[_asset].configuration.data = configuration;
    }

    function getLiquidityRate(address _asset, ReserveLogic.Tranche _tranche)
        public
        view
        returns (uint256)
    {
        return _reserves[_asset].getLiquidityRate(_tranche);
    }

    function getJuniorLiquidityIndex(address _asset)
        public
        view
        returns (uint256)
    {
        return _reserves[_asset].juniorLiquidityIndex;
    }

    function getSeniorLiquidityIndex(address _asset)
        public
        view
        returns (uint256)
    {
        return _reserves[_asset].seniorLiquidityIndex;
    }

    function getReserveNormalizedIncome(
        address _asset,
        ReserveLogic.Tranche _tranche
    ) public view returns (uint256) {
        return _reserves[_asset].getNormalizedIncome(_tranche);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function getDepositAndDebt(address _reserve)
        public
        view
        returns (DataTypes.DepositAndDebt memory)
    {
        DataTypes.ReserveData storage reserve = _reserves[_reserve];
        DataTypes.BorrowStat storage borrowStat = _borrowStat[_reserve];
        DataTypes.DepositAndDebt memory res;
        res.juniorDepositAmount = IERC20(reserve.juniorDepositTokenAddress)
            .totalSupply();
        res.seniorDepositAmount = IERC20(reserve.seniorDepositTokenAddress)
            .totalSupply();
        (res.totalDebt, res.totalInterest, res.avgBorrowRate) = (
            borrowStat.totalDebt,
            borrowStat.totalInterest,
            borrowStat.avgBorrowRate
        );
        return res;
    }

    function getPMT(
        address _reserve,
        address _vault,
        uint256 _drawDown
    ) public view returns (uint256, uint256) {
        DataTypes.DrawDown storage dd = _borrowData[_reserve][_vault].drawDowns[
            _drawDown
        ];
        return (dd.pmt.principal, dd.pmt.interest);
    }

    function getVaultDebt(address _reserve, address _vault)
        public
        view
        returns (uint256, uint256)
    {
        DataTypes.BorrowData storage borrowData = _borrowData[_reserve][_vault];
        return (borrowData.totalPrincipal, borrowData.totalInterest);
    }

    function getTotalDebt(address _reserve)
        public
        view
        returns (uint256, uint256)
    {
        DataTypes.BorrowStat storage borrowStat = _borrowStat[_reserve];
        return (borrowStat.totalDebt, borrowStat.totalInterest);
    }

    function getBorrowStat(address _reserve)
        public
        view
        returns (DataTypes.BorrowStat memory)
    {
        return _borrowStat[_reserve];
    }

    function getDrawDownList(address _reserve, address _vault)
        public
        view
        returns (uint256, uint256)
    {
        DataTypes.BorrowData storage borrowData = _borrowData[_reserve][_vault];
        return (borrowData.paidDrawDownNumber, borrowData.nextDrawDownNumber);
    }

    function getDrawDownDetail(
        address _reserve,
        address _vault,
        uint256 _drawDownId
    ) public view returns (DataTypes.DebtDetail memory) {
        DataTypes.BorrowData storage borrowData = _borrowData[_reserve][_vault];
        return borrowData.getDrawDownDetail(_drawDownId);
    }
}

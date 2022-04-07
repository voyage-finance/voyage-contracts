// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../../libraries/state/State.sol';
import '../../../libraries/types/DataTypes.sol';
import '../../../libraries/logic/ReserveLogic.sol';
import '../../../libraries/logic/ValidationLogic.sol';
import '../../../libraries/configuration/ReserveConfiguration.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';

contract LiquidityManagerStorage is State {
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeMath for uint256;

    mapping(address => DataTypes.ReserveData) internal _reserves;

    bool internal _paused;
    uint256 public juniorDepositAmount;
    uint256 public seniorDepositAmount;
    uint256 public totalDebt;

    constructor(address _liquidityManager) State(_liquidityManager) {}

    function initReserve(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress
    ) external onlyAssociatedContract {
        _reserves[_asset].init(
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _juniorIncomeAllocation,
            _seniorIncomeAllocation,
            _stableDebtAddress,
            _interestRateStrategyAddress
        );
    }

    function updateStateOnDeposit(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount
    ) public onlyAssociatedContract {
        DataTypes.ReserveData storage reserve = _reserves[_asset];
        ValidationLogic.validateDeposit(reserve, _amount);
        reserve.updateState(_tranche);
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            reserve.updateInterestRates(_asset, _amount, 0, 0, 0);
        } else {
            reserve.updateInterestRates(_asset, 0, 0, _amount, 0);
        }
    }

    function updateStateOnBorrow(address _asset, uint256 _amount)
        public
        onlyAssociatedContract
    {
        DataTypes.ReserveData storage reserve = _reserves[_asset];
        reserve.updateState(ReserveLogic.Tranche.SENIOR);
        reserve.updateInterestRates(_asset, 0, 0, 0, _amount);
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

    function increaseJuniorDeposit(uint256 _amount)
        public
        onlyAssociatedContract
    {
        juniorDepositAmount += _amount;
    }

    function increaseSeniorDeposit(uint256 _amount)
        public
        onlyAssociatedContract
    {
        seniorDepositAmount += _amount;
    }

    function decreaseJuniorDeposit(uint256 _amount)
        public
        onlyAssociatedContract
    {
        juniorDepositAmount -= _amount;
    }

    function decreaseSeniorDeposit(uint256 _amount)
        public
        onlyAssociatedContract
    {
        seniorDepositAmount -= _amount;
    }

    function increaseTotalDebt(uint256 _amount) public onlyAssociatedContract {
        totalDebt += _amount;
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

    function getDepositAndDebt()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (juniorDepositAmount, seniorDepositAmount, totalDebt);
    }
}
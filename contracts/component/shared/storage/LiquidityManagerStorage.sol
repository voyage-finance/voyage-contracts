// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../../libraries/state/State.sol';
import '../../../libraries/types/DataTypes.sol';
import '../../../libraries/logic/ReserveLogic.sol';
import '../../../libraries/logic/ValidationLogic.sol';
import '../../../libraries/configuration/ReserveConfiguration.sol';
import '../../../tokenization/StableDebtToken.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import './EscrowStorage.sol';

contract LiquidityManagerStorage is EscrowStorage {
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeMath for uint256;

    mapping(address => DataTypes.ReserveData) internal _reserves;

    // List of reserves as a map (reserveId => reserve)
    mapping(uint256 => address) internal _reserveList;

    // Maximum number of active reserves there have been in the protocol. It is the upper bound of the reserves list
    uint16 internal _reservesCount;

    bool internal _paused;

    constructor(address _liquidityManager) State(_liquidityManager) {}

    function initReserve(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress
    ) external onlyAssociatedContract {
        _reserves[_asset].init(
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _juniorIncomeAllocation,
            _seniorIncomeAllocation,
            _stableDebtAddress,
            _interestRateStrategyAddress,
            _healthStrategyAddress
        );

        _reserveList[_reservesCount] = _asset;
        _reservesCount++;
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
            reserve.juniorDepositAmount += _amount;
        } else {
            reserve.updateInterestRates(
                _asset,
                reserve.seniorDepositTokenAddress,
                _amount,
                0
            );
            reserve.seniorDepositAmount += _amount;
        }
    }

    function updateStateOnWithdraw(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount
    ) public onlyAssociatedContract {
        DataTypes.ReserveData storage reserve = _reserves[_asset];
        // todo validate withdraw
        reserve.updateState(_tranche);
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            reserve.juniorDepositAmount -= _amount;
        } else {
            reserve.updateInterestRates(
                _asset,
                reserve.seniorDepositTokenAddress,
                0,
                _amount
            );
            reserve.seniorDepositAmount -= _amount;
        }
    }

    function updateStateOnBorrow(address _asset, uint256 _amount)
        public
        onlyAssociatedContract
    {
        DataTypes.ReserveData storage reserve = _reserves[_asset];
        reserve.updateState(ReserveLogic.Tranche.SENIOR);
        reserve.updateInterestRates(
            _asset,
            reserve.seniorDepositTokenAddress,
            0,
            _amount
        );
    }

    function recordDeposit(
        address _reserve,
        ReserveLogic.Tranche _tranche,
        address _user,
        uint256 _scaledAmount,
        uint40 _timestamp
    ) public onlyAssociatedContract {
        _recordDeposit(_reserve, _tranche, _user, _scaledAmount, _timestamp);
    }

    function recordWithdrawal(
        address _reserve,
        ReserveLogic.Tranche _tranche,
        address payable _user,
        DataTypes.Withdrawal[] memory _withdrawals
    ) public onlyAssociatedContract {
        _recordWithdrawal(_reserve, _tranche, _user, _withdrawals);
    }

    function eligibleAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) public view returns (uint256, uint40) {
        return _eligibleAmount(_reserve, _user, _tranche);
    }

    function overallAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) public view returns (uint256) {
        return _overallAmount(_reserve, _user, _tranche);
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
        DataTypes.DepositAndDebt memory res;

        // todo
        res.juniorDepositAmount = reserve.juniorDepositAmount;
        res.seniorDepositAmount = reserve.seniorDepositAmount;
        (res.totalDebt, res.avgStableRate) = IStableDebtToken(
            reserve.stableDebtAddress
        ).getTotalSupplyAndAvgRate();
        return res;
    }
}

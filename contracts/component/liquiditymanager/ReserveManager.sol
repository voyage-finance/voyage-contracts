// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../Voyager.sol';
import '../../libraries/helpers/Errors.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import '../shared/storage/LiquidityManagerStorage.sol';
import '../infra/AddressResolver.sol';
import '../../libraries/proxy/Proxyable.sol';
import '../../libraries/logic/ReserveLogic.sol';
import '../../interfaces/IReserveManager.sol';
import '../../interfaces/IVoyagerComponent.sol';
import '../../interfaces/IDebtToken.sol';
import '../../interfaces/IACLManager.sol';
import '../shared/escrow/LiquidityDepositEscrow.sol';

abstract contract ReserveManager is
    Proxyable,
    IReserveManager,
    IVoyagerComponent
{
    constructor(address payable _proxy, address _voyager) Proxyable(_proxy) {
        voyager = Voyager(_voyager);
    }

    modifier onlyAdmin() {
        _requireCallerAdmin();
        _;
    }

    /************************************** HouseKeeping Functions **************************************/

    /**
     * @dev Pause the protocol
     **/
    function pause() external onlyProxy onlyAdmin {
        LiquidityManagerStorage(liquidityManagerStorageAddress()).pause();
    }

    /**
     * @dev UnPause the protocol
     **/
    function unPause() external onlyProxy onlyAdmin {
        LiquidityManagerStorage(liquidityManagerStorageAddress()).unPause();
    }

    /**
     * @dev Initializes a reserve, activating it, assigning two deposit tokens and an interest rate strategy
     * Only callable by protocol operator
     * @param _asset The address of the underlying asset of the reserve
     * @param _juniorDepositTokenAddress The address of the junior deposit token that will be assigned to the reserve
     * @param _seniorDepositTokenAddress The address of the senior deposit token that will be assigned to the reserve
     * @param _juniorIncomeAllocation Junior income allocation, express in RAY
     * @param _seniorIncomeAllocation Senior income allocation, express in RAY
     * @param _stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param _interestRateStrategyAddress The address of the interest rate strategy contract
     **/
    function initReserve(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress
    ) external onlyProxy onlyAdmin {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        LiquidityManagerStorage(liquidityManagerStorageAddress()).initReserve(
            _asset,
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _juniorIncomeAllocation,
            _seniorIncomeAllocation,
            _stableDebtAddress,
            _interestRateStrategyAddress,
            _healthStrategyAddress
        );
        proxy._emit(
            abi.encode(
                _juniorDepositTokenAddress,
                _seniorDepositTokenAddress,
                _juniorIncomeAllocation,
                _seniorIncomeAllocation,
                _stableDebtAddress,
                _interestRateStrategyAddress,
                _healthStrategyAddress
            ),
            2,
            keccak256(
                'ReverseInited(address, address,address, uint256, uint256,address,address,address)'
            ),
            bytes32(abi.encodePacked(_asset)),
            0,
            0
        );
    }

    /**
     * @dev Active a reserve for borrowing
     * @param _asset The address of the reserve
     **/
    function activeReserve(address _asset) external onlyProxy onlyAdmin {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        LiquidityManagerStorage(liquidityManagerStorageAddress()).activeReserve(
                _asset
            );
    }

    function setLoanManagerToEscrow(address _loadManager)
        external
        onlyProxy
        onlyAdmin
    {
        escrow().setLoadManager(_loadManager);
    }

    /************************************** View Functions **************************************/

    function getReserveData(address _asset)
        public
        view
        returns (DataTypes.ReserveData memory)
    {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getReserveData(_asset);
    }

    function getConfiguration(address _asset)
        public
        view
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getConfiguration(_asset);
    }

    function getFlags(address _asset)
        public
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress()).getFlags(
                _asset
            );
    }

    function getLiquidityRate(address _asset, ReserveLogic.Tranche _tranche)
        public
        view
        returns (uint256)
    {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getLiquidityRate(_asset, _tranche);
    }

    function getJuniorLiquidityIndex(address _asset)
        public
        view
        returns (uint256)
    {
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getJuniorLiquidityIndex(_asset);
    }

    function getSeniorLiquidityIndex(address _asset)
        public
        view
        returns (uint256)
    {
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getSeniorLiquidityIndex(_asset);
    }

    /************************************** Private Functions **************************************/

    function _requireCallerAdmin() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAddress(v.getACLManagerName())
        );
        require(
            aclManager.isLiquidityManager(messageSender),
            'Not vault admin'
        );
    }
}

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
import '../../interfaces/IStableDebtToken.sol';
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
        emitReserveInitialized(
            _asset,
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _juniorIncomeAllocation,
            _seniorIncomeAllocation,
            _stableDebtAddress,
            _interestRateStrategyAddress,
            _healthStrategyAddress
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

    function getReserveList() external view returns (address[] memory) {
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getReserveList();
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
        AddressResolver addressResolver = v.addressResolver();
        address aclAddress = addressResolver.getAddress(v.getACLManagerName());
        IACLManager aclManager = IACLManager(aclAddress);
        require(
            aclManager.isLiquidityManager(messageSender),
            'Not vault admin'
        );
    }

    /******************************************** Events *******************************************/

    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    event ReserveInitialized(
        address indexed _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress
    );
    bytes32 internal constant RESERVE_INITIALIZED_SIG =
        keccak256(
            'ReserveInitialized(address,address,address,uint256,uint256,address,address,address)'
        );

    function emitReserveInitialized(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress
    ) internal {
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
            RESERVE_INITIALIZED_SIG,
            addressToBytes32(_asset),
            0,
            0
        );
    }
}

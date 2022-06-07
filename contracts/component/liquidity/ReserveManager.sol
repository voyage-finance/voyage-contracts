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
import '../../interfaces/IACLManager.sol';

abstract contract ReserveManager is Proxyable, IReserveManager {
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
     * @param _interestRateStrategyAddress The address of the interest rate strategy contract
     * @param _optimalIncomeRatio The ratio of income ratio
     **/
    function initReserve(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress,
        address _loanStrategyAddress,
        uint256 _optimalIncomeRatio
    ) external onlyProxy onlyAdmin {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        LiquidityManagerStorage(liquidityManagerStorageAddress()).initReserve(
            _asset,
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _interestRateStrategyAddress,
            _healthStrategyAddress,
            _loanStrategyAddress,
            _optimalIncomeRatio
        );
        emitReserveInitialized(
            _asset,
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _interestRateStrategyAddress,
            _healthStrategyAddress,
            _optimalIncomeRatio
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
        emitReserveActivated(_asset);
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
        address aclAddress = addressResolver.getAclManager();
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
        address _stableDebtAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress,
        uint256 _optimalIncomeRatio
    );
    bytes32 internal constant RESERVE_INITIALIZED_SIG =
        keccak256(
            'ReserveInitialized(address,address,address,address,address,uint256)'
        );

    function emitReserveInitialized(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress,
        uint256 _optimalIncomeRatio
    ) internal {
        proxy._emit(
            abi.encode(
                _juniorDepositTokenAddress,
                _seniorDepositTokenAddress,
                _interestRateStrategyAddress,
                _healthStrategyAddress,
                _optimalIncomeRatio
            ),
            2,
            RESERVE_INITIALIZED_SIG,
            addressToBytes32(_asset),
            0,
            0
        );
    }

    event ReserveActivated(address indexed _asset);
    bytes32 internal constant RESERVE_ACTIVATED_SIG =
        keccak256('ReserveActivated(address)');

    function emitReserveActivated(address _asset) internal {
        bytes memory data;
        proxy._emit(
            data,
            2,
            RESERVE_ACTIVATED_SIG,
            addressToBytes32(_asset),
            0,
            0
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Tranche} from "../libraries/LibAppStorage.sol";

interface ILiquidityFacet {
    event ReserveInitialized(
        address indexed _collection,
        address indexed _currency,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _interestRateStrategyAddress
    );
    event ReserveActivated(address indexed _collection);
    event ReserveInactived(address indexed _collection);
    event Deposit(
        address indexed _collection,
        address indexed _currency,
        address indexed _user,
        Tranche _tranche,
        uint256 amount
    );
    event Withdraw(
        address indexed _collection,
        address indexed _currency,
        address indexed _user,
        Tranche _tranche,
        uint256 amount
    );

    event ProtocolFeeUpdated(address indexed _treasury, uint256 _fee);

    function initReserve(
        address _collection,
        address _currency,
        address _interestRateStrategyAddress,
        address _priceOracle
    ) external;

    function activateReserve(address _collection) external;

    function deactivateReserve(address _collection) external;

    function updateProtocolFee(address _treasuryAddr, uint40 _takeRate)
        external;

    function upgradePriceOracleImpl(address _collection, address _priceOracle)
        external;

    function updateWETH9(address _weth9) external;

    function deposit(
        address _collection,
        Tranche _tranche,
        uint256 _amount
    ) external;

    function withdraw(
        address _collection,
        Tranche _tranche,
        uint256 _amount
    ) external;

    function getReserveStatus(address _collection)
        external
        view
        returns (bool initialized, bool activated);

    function balance(
        address _collection,
        address _user,
        Tranche _tranche
    ) external view returns (uint256);

    function unbonding(address _collection, address _user)
        external
        view
        returns (uint256);

    function getReserveFlags(address _currency)
        external
        view
        returns (
            bool,
            bool,
            bool
        );
}

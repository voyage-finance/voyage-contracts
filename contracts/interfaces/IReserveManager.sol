// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IReserveManager {
    /**
     * @dev emitted when a reserve is initialized.
     * @param _reserve the address of the reserve
     * @param _jdToken the address of the overlying jdToken contract
     * @param _jdToken the address of the overlying sdToken contract
     * @param _interestRateStrategyAddress the address of the interest rate strategy for the reserve
     **/
    event ReserveInitialized(
        address indexed _reserve,
        address indexed _jdToken,
        address indexed _sdToken,
        address _interestRateStrategyAddress
    );

    /**
     * @dev emitted when a reserve is activated
     * @param _reserve the address of the reserve
     **/
    event ReserveActivated(address indexed _reserve);

    /**
     * @dev emitted when a reserve is deactivated
     * @param _reserve the address of the reserve
     **/
    event ReserveDeactivated(address indexed _reserve);

    /**
     * @dev Emitted when the state of a reserve is updated
     * @param reserve the address of the reserve
     * @param liquidityRate the new liquidity rate
     * @param currentJuniorLiquidityIndex the new junior liquidity index
     * @param currentSeniorLiquidityIndex the new senior liquidity index
     **/
    event ReserveUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 currentJuniorLiquidityIndex,
        uint256 currentSeniorLiquidityIndex
    );
}

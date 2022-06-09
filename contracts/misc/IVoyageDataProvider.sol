// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../libraries/types/DataTypes.sol";

interface IVoyageDataProvider {
    function getPoolTokens()
        external
        view
        returns (DataTypes.FungibleTokenData[] memory tokens);

    function getPoolData(address underlyingAsset)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 juniorLiquidity,
            uint256 seniorLiquidity,
            uint256 juniorLiquidityRate,
            uint256 seniorLiquidityRate,
            uint256 totalDebt,
            uint256 borrowRate,
            uint256 trancheRatio
        );

    function getPoolConfiguration(address _reserve)
        external
        view
        returns (DataTypes.PoolConfiguration memory);

    function userPoolData(address underlyingAsset, address user)
        external
        view
        returns (uint256 juniorTrancheBalance, uint256 seniorTrancheBalance);

    function getVaults()
        external
        view
        returns (address[] memory vaultAddresses);

    /**
     * @notice get the address of vault managed by this address
     * @param user address
     * @return vaultAddress the vault address. if no vault exists for this address, returns 0x0
     **/
    function getUserVaults(address user)
        external
        view
        returns (address vaultAddress);

    /**
     * @notice Returns vault data for a given underlying credit asset
     * @param vaultAddress the vault contract address, returned by getVaults
     * @param underlyingPool the address of the pool asset for which you want to get the vault state
     **/
    function getVaultData(address vaultAddress, address underlyingPool)
        external
        view
        returns (
            uint256 borrowRate,
            uint256 totalDebt,
            uint256 totalSecurityDeposit,
            uint256 withdrawableSecurityDeposit,
            uint256 creditLimit,
            uint256 spendableBalance,
            uint256 gav,
            uint256 ltv,
            uint256 minRepaymentRate,
            uint256 aggregateRepaymentRate,
            uint256 healthFactor
        );

    /**
     * @notice Returns the actual draw downs for a vault and underlying asset pool
     * @param vaultAddress vault contract address
     * @param underlyingPool address of the underlying pool asset (ERC20)
     * @return principal principal amount borrowed
     * @return balance balance the outstanding compounded balance to be repaid
     * @return amountRepaid the total repaid amount from origination
     * @return tenure the underlying term of the draw down
     * @return minRepaymentRate minimum repayment per second
     * @return timestamp block timestamp at time of origination
     **/
    function getVaultDebt(address vaultAddress, address underlyingPool)
        external
        view
        returns (
            uint256 principal,
            uint256 balance,
            uint256 amountRepaid,
            uint256 tenure,
            uint256 minRepaymentRate,
            uint256 timestamp
        );

    function getVaultFungibleAssets(
        address vaultAddress,
        address underlyingPool
    ) external view returns (uint256 earningsBalance, uint256 creditBalance);

    /**
     * @notice returns the vault's collateralised assets (i.e. not repaid)
     * @param vaultAddress the vault address
     * @param underlyingPool the address of the underlying pool's ERC20 asset
     * @param underlyingCollection address of the collateralised NFT collection
     * @return floorPrice the **current** floor price
     * @return gav the gav based on the floor
     * @return ids ERC721 token IDs
     **/
    function getVaultCollateral(
        address vaultAddress,
        address underlyingPool,
        address underlyingCollection
    )
        external
        view
        returns (
            uint256 floorPrice,
            uint256 gav,
            uint256[] memory ids
        );

    /**
     * @notice returns the details of a specific collateralised asset (i.e. not repaid)
     * @param vaultAddress the vault's address
     * @param underlyingPool the address of the underlying pool's ERC20 asset
     * @param id the ID of the collateral asset
     * @param underlyingCollection address of the collateralised NFT collection
     * @return currentValue the **current** value of the asset (collection floor)
     * @return purchasePrice the value of the asset at purchase
     * @return protocolFee fees taken by the protocol
     * @return affiliateFee fees taken by protocol affiliates
     **/
    function getVaultCollateralDetail(
        address vaultAddress,
        address underlyingPool,
        uint256 id,
        address underlyingCollection
    )
        external
        view
        returns (
            uint256 currentValue,
            uint256 purchasePrice,
            uint256 protocolFee,
            uint256 affiliateFee
        );
}

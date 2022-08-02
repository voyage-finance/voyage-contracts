// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {LibAppStorage, AppStorage, BorrowData, VaultConfig, NFTInfo, DiamondFacet, ReserveConfigurationMap} from "./LibAppStorage.sol";
import {LibReserveConfiguration} from "./LibReserveConfiguration.sol";
import {IExternalAdapter} from "../interfaces/IExternalAdapter.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";
import {VaultDataFacet} from "../../vault/facets/VaultDataFacet.sol";
import {VaultAssetFacet} from "../../vault/facets/VaultAssetFacet.sol";
import {LogarithmMath} from "../../shared/libraries/LogarithmMath.sol";

library LibVault {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    function recordVault(address _owner, address _vault)
        internal
        returns (uint256)
    {
        AppStorage storage s = LibAppStorage.ds();
        require(s.vaultMap[_owner] == address(0), "one vault per owner");
        s.vaults.push(_vault);
        LibAppStorage.ds().vaultMap[_owner] = _vault;
        return (s.vaults.length);
    }

    function setVaultBeacon(address _impl) internal {
        AppStorage storage s = LibAppStorage.ds();
        s.vaultBeacon = new UpgradeableBeacon(_impl);
    }

    function setVaultConfig(
        address _collection,
        address _vault,
        uint256 _min,
        uint256 _max,
        uint256 _marginRequirement
    ) internal {
        AppStorage storage s = LibAppStorage.ds();
        address currency = s._reserveData[_collection].currency;
        VaultConfig memory config = VaultConfig({
            minMargin: _min,
            maxMargin: _max,
            marginRequirement: _marginRequirement,
            overrideGlobal: true,
            currency: currency
        });
        s.vaultConfigMap[currency][_vault] = config;
    }

    function updateNFTPrice(
        address _collection,
        uint256 _cardId,
        uint256 _cardPrice
    ) internal {
        AppStorage storage s = LibAppStorage.ds();
        s.nftInfo[_collection][_cardId].price = _cardPrice;
        s.nftInfo[_collection][_cardId].timestamp = block.timestamp;
    }

    function setNFTInfo(
        address _collection,
        address _currency,
        address _marketPlace
    ) internal {
        AppStorage storage s = LibAppStorage.ds();
        s.marketPlaceToAsset[_marketPlace] = _collection;
        s.erc721AssetInfo[_collection].marketplace = _marketPlace;
        s.erc721AssetInfo[_collection].erc20Addr = _currency;
    }

    /* ----------------------------- view functions ----------------------------- */
    function vaultBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.ds();
        return address(s.vaultBeacon);
    }

    function marginEscrowBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.ds();
        return address(s.marginEscrowBeacon);
    }

    function creditEscrowBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.ds();
        return address(s.creditEscrowBeacon);
    }

    function subVaultBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.ds();
        return address(s.subVaultBeacon);
    }

    function getVaultAddress(address _owner) internal view returns (address) {
        return LibAppStorage.ds().vaultMap[_owner];
    }

    function getVaultDebt(
        address _collection,
        address _currency,
        address _vault
    ) internal view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.ds();
        BorrowData storage borrowData = s._borrowData[_collection][_currency][
            _vault
        ];
        return (borrowData.totalPrincipal, borrowData.totalInterest);
    }

    function getDiamondFacets() internal view returns (DiamondFacet memory) {
        AppStorage storage s = LibAppStorage.ds();
        return s.diamondFacet;
    }

    function getTotalPaidAndRedeemed(
        address _collection,
        address _currency,
        address _vault
    ) internal view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.ds();
        BorrowData storage borrowData = s._borrowData[_collection][_currency][
            _vault
        ];
        return (borrowData.totalPaid, borrowData.totalRedeemed);
    }

    function increaseTotalRedeemed(
        address _collection,
        address _currency,
        address _vault,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.ds();
        BorrowData storage borrowData = s._borrowData[_collection][_currency][
            _vault
        ];
        borrowData.totalRedeemed = borrowData.totalRedeemed + _amount;
    }

    function getVaultConfig(address _collection, address _vault)
        internal
        view
        returns (VaultConfig memory)
    {
        AppStorage storage s = LibAppStorage.ds();
        address currency = s._reserveData[_collection].currency;
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_collection);
        uint256 decimals = conf.getDecimals();
        uint256 assetUnit = 10**decimals;
        VaultConfig memory vaultConfig = s.vaultConfigMap[currency][_vault];
        if (!vaultConfig.overrideGlobal) {
            (
                vaultConfig.minMargin,
                vaultConfig.maxMargin,
                vaultConfig.marginRequirement
            ) = LibReserveConfiguration
                .getConfiguration(_collection)
                .getMarginParams();
        }
        vaultConfig.minMargin = vaultConfig.minMargin * assetUnit;
        vaultConfig.maxMargin = vaultConfig.maxMargin * assetUnit;
        vaultConfig.currency = currency;

        return vaultConfig;
    }

    function getTokenAddrByMarketPlace(address _marketplace)
        internal
        view
        returns (address)
    {
        AppStorage storage s = LibAppStorage.ds();
        return s.marketPlaceToAsset[_marketplace];
    }

    function getMarketPlaceByAsset(address _currency)
        internal
        view
        returns (address)
    {
        AppStorage storage s = LibAppStorage.ds();
        return s.erc721AssetInfo[_currency].marketplace;
    }

    function getERC20ByAsset(address _currency)
        internal
        view
        returns (address)
    {
        AppStorage storage s = LibAppStorage.ds();
        return s.erc721AssetInfo[_currency].erc20Addr;
    }

    function getCollectionInfo(address _collection, uint256 _tokenId)
        internal
        view
        returns (NFTInfo memory)
    {
        AppStorage storage s = LibAppStorage.ds();
        return s.nftInfo[_collection][_tokenId];
    }

    /**
     * @dev Get credit limit for a specific reserve
     * @param _vault vault address
     * @return _collection collection address
     **/
    function getCreditLimit(
        address _vault,
        address _collection,
        address _currency,
        uint256 _fv
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.ds();
        int128 rep = s
        ._borrowState[_collection][_currency]
            .numRepaidLoans[_vault]
            .repaidTimes;
        uint256 multiplier = uint256(int256(LogarithmMath.log_2(rep + 1) + 1));
        return _fv * multiplier;
    }
}

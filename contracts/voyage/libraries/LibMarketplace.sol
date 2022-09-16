// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IVault} from "../../vault/Vault.sol";
import {IMarketPlaceAdapter, AssetInfo} from "../interfaces/IMarketPlaceAdapter.sol";
import {Storage, LibAppStorage} from "./LibAppStorage.sol";

library LibMarketplace {
    function purchase(
        address _marketplace,
        address _vault,
        uint256 _value,
        bytes calldata _data
    ) internal {
        address adapterAddr = LibAppStorage
            .ds()
            .marketPlaceData[_marketplace]
            .adapterAddr;
        bytes memory data = IMarketPlaceAdapter(adapterAddr).execute(_data);
        bytes memory encodedData = abi.encode(_marketplace, data);
        IVault(_vault).execute(encodedData, _value);
    }

    function extractAssetInfo(address _marketplace, bytes calldata _data)
        internal
        view
        returns (AssetInfo memory)
    {
        address adapterAddr = LibAppStorage
            .ds()
            .marketPlaceData[_marketplace]
            .adapterAddr;

        return IMarketPlaceAdapter(adapterAddr).extractAssetInfo(_data);
    }
}

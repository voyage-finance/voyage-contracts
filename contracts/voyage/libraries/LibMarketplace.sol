// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IVault} from "../../vault/Vault.sol";
import {IMarketPlaceAdapter, AssetInfo} from "../interfaces/IMarketPlaceAdapter.sol";
import {Storage, LibAppStorage} from "./LibAppStorage.sol";
import {Storage, LibAppStorage} from "../libraries/LibAppStorage.sol";

library LibMarketplace {
    function purchase(
        address _marketplace,
        address _vault,
        uint256 _value,
        bytes memory _data
    ) internal {
        address adapterAddr = LibAppStorage
            .ds()
            .marketPlaceData[_marketplace]
            .adapterAddr;

        (bool success, bytes memory data) = adapterAddr.delegatecall(
            abi.encodeWithSelector(
                IMarketPlaceAdapter(address(0)).execute.selector,
                _data,
                _vault,
                _marketplace,
                _value
            )
        );
        if (!success) {
            revert(string(data));
        }
    }

    function extractAssetInfo(address _marketplace, bytes memory _data)
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

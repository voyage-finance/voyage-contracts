// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VaultManageFacet} from "../../vault/facets/VaultManageFacet.sol";
import {IMarketPlaceAdapter} from "../interfaces/IMarketPlaceAdapter.sol";
import {Storage, LibAppStorage} from "../libraries/LibAppStorage.sol";

contract MarketplaceAdapterFacet is Storage {
    function purchase(
        address _marketplace,
        address _vault,
        bytes calldata _data
    ) external {
        require(msg.sender == address(this), "Invalid caller");
        address adapterAddr = LibAppStorage
            .ds()
            .marketPlaceData[_marketplace]
            .adapterAddr;
        bytes memory data = IMarketPlaceAdapter(adapterAddr).execute(_data);
        bytes memory encodedData = abi.encode(_marketplace, data);
        VaultManageFacet(_vault).exec(encodedData);
    }

    function extractAssetPrice(address _marketplace, bytes calldata _data)
        external
        view
        returns (uint256)
    {
        address adapterAddr = LibAppStorage
            .ds()
            .marketPlaceData[_marketplace]
            .adapterAddr;

        return IMarketPlaceAdapter(adapterAddr).extractAssetPrice(_data);
    }

    function updateMarketPlaceData(address _marketplace, address _strategy)
        external
        authorised
    {
        LibAppStorage
            .ds()
            .marketPlaceData[_marketplace]
            .adapterAddr = _strategy;
    }
}

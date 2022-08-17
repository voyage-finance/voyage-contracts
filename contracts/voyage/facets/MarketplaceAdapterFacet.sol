// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IVault} from "../../vault/Vault.sol";
import {IMarketPlaceAdapter} from "../interfaces/IMarketPlaceAdapter.sol";
import {Storage, LibAppStorage} from "../libraries/LibAppStorage.sol";

contract MarketplaceAdapterFacet is Storage {
    event MarketplaceAdapterUpdated(
        address indexed _marketplace,
        address _strategy
    );

    function purchase(
        address _marketplace,
        address _vault,
        bytes calldata _data
    ) external {
        if (msg.sender != address(this)) {
            revert InvalidCaller();
        }
        address adapterAddr = LibAppStorage
            .ds()
            .marketPlaceData[_marketplace]
            .adapterAddr;
        bytes memory data = IMarketPlaceAdapter(adapterAddr).execute(_data);
        bytes memory encodedData = abi.encode(_marketplace, data);
        IVault(_vault).execute(encodedData);
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
        emit MarketplaceAdapterUpdated(_marketplace, _strategy);
    }

    error InvalidCaller();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibAppStorage, MarketPlaceType, Storage} from "../libraries/LibAppStorage.sol";
import {LibLooksRare} from "../libraries/LibLooksRare.sol";
import {LibOpensea} from "../libraries/LibOpensea.sol";
import {VaultExternalFacet} from "../../vault/facets/VaultExternalFacet.sol";

contract MarketplaceAdapterFacet is Storage {
    function purchase(
        address _marketplace,
        address _vault,
        bytes calldata _data
    ) public {
        require(msg.sender == address(this), "Invalid caller");
        MarketPlaceType marketplaceType = LibAppStorage.ds().marketplace[
            _marketplace
        ];
        if (marketplaceType == MarketPlaceType.Unknown) {
            revert();
        }
        if (marketplaceType == MarketPlaceType.LooksRare) {
            bytes memory data = LibLooksRare.asmExecuteData(_data);
            bytes memory encodedData = abi.encode(_marketplace, data);
            VaultExternalFacet(_vault).exec(encodedData);
        }
        if (marketplaceType == MarketPlaceType.OpenSea) {
            LibOpensea.asmExecuteData(_data);
        }
    }

    function extractAssetPrice(address _marketplace, bytes calldata _data)
        public
        view
        returns (uint256)
    {
        MarketPlaceType marketplaceType = LibAppStorage.ds().marketplace[
            _marketplace
        ];
        if (marketplaceType == MarketPlaceType.Unknown) {
            return 0;
        }
        if (marketplaceType == MarketPlaceType.LooksRare) {
            return LibLooksRare.extractAssetPrice(_data);
        }
        if (marketplaceType == MarketPlaceType.OpenSea) {
            // todo
            return 0;
        }
    }
}

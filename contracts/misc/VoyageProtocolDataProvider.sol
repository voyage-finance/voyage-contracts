// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/types/DataTypes.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/ILiquidityManager.sol';

contract VoyageProtocolDataProvider {
    IAddressResolver public addressResolver;

    constructor(IAddressResolver _addressResolver) {
        addressResolver = _addressResolver;
    }

    function getPoolTokens()
        external
        view
        returns (DataTypes.FungibleTokenData[] memory tokens)
    {
        ILiquidityManager(addressResolver.getLiquidityManagerProxy());
        DataTypes.FungibleTokenData[]
            memory reserves = new DataTypes.FungibleTokenData[](1);
        return reserves;
    }
}

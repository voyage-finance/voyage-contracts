// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/types/DataTypes.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/IReserveManager.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/extensions/IERC20Metadata.sol';

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
        address[] memory reserveList = IReserveManager(
            addressResolver.getLiquidityManagerProxy()
        ).getReserveList();

        DataTypes.FungibleTokenData[]
            memory reserves = new DataTypes.FungibleTokenData[](
                reserveList.length
            );

        for (uint256 i = 0; i < reserveList.length; i++) {
            address reserveAddress = reserveList[i];
            //        DataTypes.ReserveData memory reserveData = IReserveManager(
            //                addressResolver.getLiquidityManagerProxy()
            //            ).getReserveData(reserveAddress);
            reserves[i] = DataTypes.FungibleTokenData({
                symbol: IERC20Metadata(reserveAddress).symbol(),
                tokenAddress: reserveAddress
            });
        }

        return reserves;
    }
}

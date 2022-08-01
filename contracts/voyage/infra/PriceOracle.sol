// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";

contract PriceOracle is IPriceOracle, Ownable {
    using WadRayMath for uint256;

    struct AveragePrice {
        uint256 blockTimestamp;
        uint256 priceAverage;
    }

    mapping(address => AveragePrice) prices;

    function getTwap(address _currency)
        external
        view
        returns (uint256, uint256)
    {
        return (
            prices[_currency].priceAverage,
            prices[_currency].blockTimestamp
        );
    }

    function updateTwap(address _currency, uint256 _priceAverage)
        external
        onlyOwner
    {
        prices[_currency].priceAverage = _priceAverage;
        prices[_currency].blockTimestamp = block.timestamp;
    }
}

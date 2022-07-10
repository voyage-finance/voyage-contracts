// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";

contract PriceOracle is IPriceOracle, Ownable {
    using WadRayMath for uint256;

    struct CumulativePrice {
        uint256 priceCumulativeLast;
        uint256 blockTimestampLast;
        uint256 priceAverage;
    }

    struct PriceData {
        uint256 priceCumulative;
        uint256 blockTimestamp;
    }

    mapping(address => CumulativePrice) prices;
    mapping(address => PriceData) ticket;

    function getAssetPrice(address _asset) external view returns (uint256) {
        return prices[_asset].priceAverage;
    }

    function updateAssetPrice(address _asset) external onlyOwner {
        _updateAssetPrice(_asset);
    }

    function updateAssetPrices(address[] calldata _assets) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            _updateAssetPrice(_assets[i]);
        }
    }

    function updateCumulative(address _asset, uint256 _price)
        external
        onlyOwner
    {
        _updateCumulative(_asset, _price);
    }

    function updateCumulativeBatch(
        address[] calldata _assets,
        uint256[] calldata _prices
    ) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            _updateCumulative(_assets[i], _prices[i]);
        }
    }

    function currentCumulativePrice(address _asset)
        public
        view
        returns (uint256, uint256)
    {
        PriceData storage pd = ticket[_asset];
        return (pd.priceCumulative, pd.blockTimestamp);
    }

    function _updateAssetPrice(address _asset) internal {
        CumulativePrice storage cp = prices[_asset];
        // period check
        (
            uint256 priceCumulative,
            uint256 blockTimeStamp
        ) = currentCumulativePrice(_asset);
        uint256 timeElapsed = blockTimeStamp - cp.blockTimestampLast;
        cp.priceAverage =
            (priceCumulative - cp.priceCumulativeLast) /
            timeElapsed;
        cp.priceCumulativeLast = priceCumulative;
        cp.blockTimestampLast = blockTimeStamp;
    }

    function _updateCumulative(address _asset, uint256 _price) internal {
        PriceData storage pd = ticket[_asset];
        uint256 timeElapsed = block.timestamp - pd.blockTimestamp;
        pd.priceCumulative = pd.priceCumulative + _price * timeElapsed;
        pd.blockTimestamp = block.timestamp;
    }
}

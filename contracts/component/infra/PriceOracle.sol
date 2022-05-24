// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../interfaces/IPriceOracle.sol';
import '../Voyager.sol';

contract PriceOracle is IPriceOracle {
    using SafeMath for uint256;
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

    modifier onlyAdmin() {
        _requireCallerAdmin();
        _;
    }

    mapping(address => CumulativePrice) prices;
    mapping(address => PriceData) ticket;

    Voyager voyager;

    constructor(address _voyager) {
        voyager = Voyager(_voyager);
    }

    function getAssetPrice(address _asset) external view returns (uint256) {
        return prices[_asset].priceAverage;
    }

    function updateAssetPrice(address _asset) external onlyAdmin {
        _updateAssetPrice(_asset);
    }

    function updateAssetPrices(address[] calldata _assets) external onlyAdmin {
        for (uint256 i = 0; i < _assets.length; i++) {
            _updateAssetPrice(_asset);
        }
    }

    function updateCumulative(address _asset, uint256 _price)
        external
        onlyAdmin
    {
        _updateCumulative(_asset, _price);
    }

    function updateCumulativeBatch(
        address[] calldata _assets,
        uint256[] calldata _prices
    ) external onlyAdmin {
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
        cp.priceAverage = priceCumulative.sub(cp.priceCumulativeLast).div(
            timeElapsed
        );
        cp.priceCumulativeLast = priceCumulative;
        cp.blockTimestampLast = blockTimeStamp;
        emit AssetPriceUpdated(_asset, cp.priceAverage, block.timestamp);
    }

    function _updateCumulative(address _asset, uint256 _price) internal {
        PriceData storage pd = ticket[_asset];
        uint256 timeElapsed = block.timestamp.sub(pd.blockTimestamp);
        pd.priceCumulative = pd.priceCumulative.add(_price.mul(timeElapsed));
        pd.blockTimestamp = block.timestamp;
    }

    function _requireCallerAdmin() internal {
        IACLManager aclManager = IACLManager(
            voyager.addressResolver().getAclManager()
        );
        require(aclManager.isOracleManager(msg.sender), 'Not oracle admin');
    }
}

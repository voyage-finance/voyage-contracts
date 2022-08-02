// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";

contract PriceOracle is IPriceOracle, Ownable {
    mapping(address => bool) _operators;

    modifier auth() {
        if (!_operators[msg.sender] && msg.sender != owner()) {
            revert InvalidOperator();
        }
        _;
    }

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
        auth
    {
        prices[_currency].priceAverage = _priceAverage;
        prices[_currency].blockTimestamp = block.timestamp;
    }

    function setOperator(address _operator, bool enabled) external onlyOwner {
        if (enabled) {
            _operators[_operator] = true;
        } else {
            delete _operators[_operator];
        }
    }
}

error InvalidOperator();

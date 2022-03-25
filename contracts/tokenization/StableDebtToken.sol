// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/IStableDebtToken.sol';
import '../libraries/math/WadRayMath.sol';
import '../component/infra/AddressResolver.sol';

contract StableDebtToken {
    using WadRayMath for uint256;

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;

    AddressResolver internal addressResolver;
    address internal _underlyingAsset;

    function initialize() public {}
}

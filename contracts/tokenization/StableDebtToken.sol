// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/math/WadRayMath.sol';
import '../interfaces/IInitializableDebtToken.sol';
import '../component/infra/AddressResolver.sol';
import './DebtTokenBase.sol';

contract StableDebtToken is IInitializableDebtToken, DebtTokenBase {
    using WadRayMath for uint256;

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;

    uint256 internal _avgStableRate;
    mapping(address => uint40) internal _timestamps;
    mapping(address => uint256) internal _usersStableRate;
    uint40 internal _totalSupplyTimestamp;

    AddressResolver internal addressResolver;
    address internal underlyingAsset;

    function initialize(
        address _underlyingAsset,
        uint8 _debtTokenDecimals,
        string memory _debtTokenName,
        string memory _debtTokenSymbol,
        bytes calldata _params
    ) public {
        _setName(_debtTokenName);
        _setSymbol(_debtTokenSymbol);
        _setDecimals(_debtTokenDecimals);

        underlyingAsset = _underlyingAsset;

        emit Initialized(
            underlyingAsset,
            _debtTokenDecimals,
            _debtTokenName,
            _debtTokenSymbol,
            _params
        );
    }

    /**
     * @dev Gets the revision of the stable debt token implementation
     * @return The debt token implementation revision
     **/
    function getRevision() internal pure virtual returns (uint256) {
        return DEBT_TOKEN_REVISION;
    }

    /**
     * @dev Returns the average stable rate
     **/
    function getAverageStableRate() external view override returns (uint256) {
        return _avgStableRate;
    }

    function _getUnderlyingAssetAddress()
        internal
        view
        override
        returns (address)
    {
        return underlyingAsset;
    }
}

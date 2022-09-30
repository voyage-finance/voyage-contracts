// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultFacet {
    event VaultCreated(
        address _vault,
        address _owner,
        uint256 _numVaults,
        uint256 refundAmount
    );
    event VaultMarginCredited(
        address indexed _vault,
        address indexed _asset,
        address _sponsor,
        uint256 _amount
    );
    event VaultMarginRedeemed(
        address indexed _vault,
        address indexed _asset,
        address _sponsor,
        uint256 _amount
    );
    event VaultImplementationUpdated(address _impl);

    function createVault(
        address _user,
        bytes20 _salt,
        uint256 _gasUnits,
        uint256 _gasPrice
    ) external;

    function getVaultImpl() external view returns (address);

    function setVaultImpl(address _impl) external;

    function withdrawNFT(
        address _vault,
        address _collection,
        uint256 _tokenId
    ) external;

    function transferCurrency(
        address _vault,
        address _currency,
        address _to,
        uint256 _amount
    ) external;

    function wrapVaultETH(address _vault, uint256 _value) external;

    function unwrapVaultETH(address _vault, uint256 _vaule) external;

    function approveMarketplace(
        address _vault,
        address _marketplace,
        bool revoke
    ) external;

    function computeCounterfactualAddress(address _user, bytes20 _salt)
        external
        view
        returns (address);

    function collectionInitialized(address _collection)
        external
        view
        returns (bool);

    function subVaultBeacon() external view returns (address);

    function getVaultAddr(address _user) external view returns (address);
}

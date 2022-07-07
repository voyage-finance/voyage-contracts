// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {LibAppStorage, AppStorage, BorrowData, VaultConfig, NFTInfo} from "./LibAppStorage.sol";
import {IExternalAdapter} from "../interfaces/IExternalAdapter.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {VaultDataFacet} from "../../vault/facets/VaultDataFacet.sol";
import {VaultAssetFacet} from "../../vault/facets/VaultAssetFacet.sol";

library LibVault {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    function recordVault(address _owner, address _vault)
        internal
        returns (uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.vaultMap[_owner] == address(0), "one vault per owner");
        s.vaults.push(_vault);
        LibAppStorage.diamondStorage().vaultMap[_owner] = _vault;
        return (s.vaults.length);
    }

    function initVaultAsset(address _vault, address _asset)
        internal
        returns (address)
    {
        address escrow = VaultAssetFacet(_vault).initAsset(_asset);
        return escrow;
    }

    function setMaxMargin(address _reserve, uint256 _amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vaultConfigMap[_reserve].maxMargin = _amount;
    }

    function setMinMargin(address _reserve, uint256 _amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vaultConfigMap[_reserve].minMargin = _amount;
    }

    function setMarginRequirement(address _reserve, uint256 _requirement)
        internal
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vaultConfigMap[_reserve].marginRequirement = _requirement;
    }

    function updateNFTPrice(
        address _erc721Addr,
        uint256 _cardId,
        uint256 _cardPrice
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.nftInfo[_erc721Addr][_cardId].price = _cardPrice;
        s.nftInfo[_erc721Addr][_cardId].timestamp = block.timestamp;
    }

    function setNFTInfo(
        address _nft721,
        address _erc20,
        address _marketPlace
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.marketPlaceToAsset[_marketPlace] = _nft721;
        s.erc721AssetInfo[_nft721].marketplace = _marketPlace;
        s.erc721AssetInfo[_nft721].erc20Addr = _erc20;
    }

    /* ----------------------------- view functions ----------------------------- */
    function marginEscrowBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return address(s.marginEscrowBeacon);
    }

    function creditEscrowBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return address(s.creditEscrowBeacon);
    }

    function subVaultBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return address(s.subVaultBeacon);
    }

    function getVaultAddress(address _owner) internal view returns (address) {
        return LibAppStorage.diamondStorage().vaultMap[_owner];
    }

    function getVaultEscrowAddress(address _owner, address _asset)
        internal
        view
        returns (address, address)
    {
        address creditEscrow = VaultDataFacet(getVaultAddress(_owner))
            .creditEscrow(_asset);
        address marginEscrow = VaultDataFacet(getVaultAddress(_owner))
            .marginEscrow(_asset);
        return (creditEscrow, marginEscrow);
    }

    function getVaultDebt(address _reserve, address _vault)
        internal
        view
        returns (uint256, uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_reserve][_vault];
        return (borrowData.totalPrincipal, borrowData.totalInterest);
    }

    function getTotalPaidAndRedeemed(address _reserve, address _vault)
        internal
        view
        returns (uint256, uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_reserve][_vault];
        return (borrowData.totalPaid, borrowData.totalRedeemed);
    }

    function increaseTotalRedeemed(
        address _reserve,
        address _vault,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_reserve][_vault];
        borrowData.totalRedeemed = borrowData.totalRedeemed.add(_amount);
    }

    function getVaultConfig(address _reserve)
        internal
        view
        returns (VaultConfig memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.vaultConfigMap[_reserve];
    }

    function getTokenAddrByMarketPlace(address _marketplace)
        internal
        view
        returns (address)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.marketPlaceToAsset[_marketplace];
    }

    function getMarketPlaceByAsset(address _asset)
        internal
        view
        returns (address)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.erc721AssetInfo[_asset].marketplace;
    }

    function getERC20ByAsset(address _asset) internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.erc721AssetInfo[_asset].erc20Addr;
    }

    function getNFTInfo(address _erc721Addr, uint256 _tokenId)
        internal
        view
        returns (NFTInfo memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.nftInfo[_erc721Addr][_tokenId];
    }

    /**
     * @dev Get available credit
     * @param _vault user address
     * @param _reserve reserve address
     **/
    function getAvailableCredit(address _vault, address _reserve)
        internal
        view
        returns (uint256)
    {
        uint256 creditLimit = getCreditLimit(_vault, _reserve);
        uint256 principal;
        uint256 interest;
        (principal, interest) = getVaultDebt(_reserve, _vault);
        uint256 accumulatedDebt = principal.add(interest);
        if (creditLimit < accumulatedDebt) {
            return 0;
        }

        return creditLimit - accumulatedDebt;
    }

    /**
     * @dev Get credit limit for a specific reserve
     * @param _vault vault address
     * @return _reserve reserve address
     **/
    function getCreditLimit(address _vault, address _reserve)
        internal
        view
        returns (uint256)
    {
        uint256 currentMargin = getMargin(_vault, _reserve);
        VaultConfig memory vc = getVaultConfig(_reserve);
        uint256 marginRequirement = vc.marginRequirement;
        require(marginRequirement != 0, "margin requirement cannot be 0");
        uint256 creditLimitInRay = currentMargin.wadToRay().rayDiv(
            marginRequirement
        );
        return creditLimitInRay.rayToWad();
    }

    function getMargin(address _vault, address _reserve)
        internal
        view
        returns (uint256)
    {
        return VaultDataFacet(_vault).getCurrentMargin(_reserve);
    }

    function getWithdrawableMargin(
        address _vault,
        address _reserve,
        address _user
    ) internal view returns (uint256) {
        return VaultDataFacet(_vault).withdrawableMargin(_reserve, _user);
    }

    function getTotalWithdrawableMargin(address _vault, address _reserve)
        internal
        view
        returns (uint256)
    {
        return VaultDataFacet(_vault).totalWithdrawableMargin(_reserve);
    }
}

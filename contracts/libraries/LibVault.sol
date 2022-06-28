// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Vault} from "../component/vault/Vault.sol";
import {MarginEscrow} from "../component/vault/MarginEscrow.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IExternalAdapter} from "../interfaces/IExternalAdapter.sol";
import {LibAppStorage, AppStorage, BorrowData, VaultConfig, NFTInfo} from "./LibAppStorage.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library LibVault {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    function deployVault(
        address _voyager,
        address _owner,
        address _reserve
    ) internal returns (address, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.vaultMap[_owner] == address(0), "one vault per owner");
        if (address(s.vaultBeacon) == address(0)) {
            Vault vault = new Vault();
            s.vaultBeacon = new UpgradeableBeacon(address(vault));
        }
        BeaconProxy proxy = new BeaconProxy(
            address(s.vaultBeacon),
            abi.encodeWithSelector(
                Vault(address(0)).initialize.selector,
                _voyager,
                _owner
            )
        );
        address vault = address(proxy);
        require(vault != address(0), "deploy vault failed");
        s.vaults.push(vault);
        s.vaultMap[_owner] = vault;
        return (vault, s.vaults.length);
    }

    function initVaultAsset(address _vault, address _asset)
        internal
        returns (address)
    {
        address escrow = IVault(_vault).initAsset(_asset);
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

    function setVaultStrategyAddr(address _target, address _strategyAddr)
        internal
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vaultStrategy[_target] = _strategyAddr;
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

    function updateVaultImplContract(address _vault) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vaultBeacon.upgradeTo(_vault);
    }

    function validate(
        address _target,
        bytes4 _selector,
        bytes calldata _payload
    ) internal returns (address, bytes memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return
            IExternalAdapter(s.vaultStrategy[_target]).validate(
                _target,
                _selector,
                _payload
            );
    }

    /* ----------------------------- view functions ----------------------------- */
    function getVaultAddress(address _owner) internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.vaultMap[_owner];
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

    function getNFTPrice(address _erc721Addr, uint256 _tokenId)
        internal
        view
        returns (uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.nftInfo[_erc721Addr][_tokenId].price;
    }

    function getNFTInfo(address _erc721Addr, uint256 _tokenId)
        internal
        view
        returns (NFTInfo memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.nftInfo[_erc721Addr][_tokenId];
    }

    function getERC721Addr(address _target) internal returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return IExternalAdapter(s.vaultStrategy[_target]).getERC721();
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
        return IVault(_vault).getCurrentMargin(_reserve);
    }

    function getWithdrawableMargin(
        address _vault,
        address _reserve,
        address _user
    ) internal view returns (uint256) {
        return IVault(_vault).withdrawableMargin(_reserve, _user);
    }

    function getTotalWithdrawableMargin(address _vault, address _reserve)
        internal
        view
        returns (uint256)
    {
        return IVault(_vault).totalWithdrawableMargin(_reserve);
    }
}

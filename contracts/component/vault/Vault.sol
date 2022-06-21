// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {MarginEscrow} from "./MarginEscrow.sol";
import {AddressResolver} from "../infra/AddressResolver.sol";
import {Voyager} from "../Voyager.sol";
import {VaultFacet} from "../facets/VaultFacet.sol";
import {LoanFacet} from "../facets/LoanFacet.sol";
import {VaultConfig} from "../../libraries/LibAppStorage.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IAddressResolver} from "../../interfaces/IAddressResolver.sol";
import {PriorityQueue, Heap} from "../../libraries/logic/PriorityQueue.sol";
import "hardhat/console.sol";

contract Vault is ReentrancyGuard, Initializable, IVault, IERC1271, IERC165 {
    using WadRayMath for uint256;
    using SafeMath for uint256;
    using PriorityQueue for Heap;

    // about to remove or refactor
    address voyager;

    struct VaultStorageV1 {
        address owner;
        MarginEscrow marginEscrow;
        mapping(address => Heap) nfts;
        /// @dev You must not set element 0xffffffff to true
        mapping(bytes4 => bool) supportedInterfaces;
    }

    modifier onlyVoyager() {
        require(msg.sender == voyager, "Not Voyager");
        _;
    }

    function initialize(
        address _voyager,
        address _owner,
        address _reserve,
        address _marginEscrow
    ) external initializer {
        voyager = _voyager;
        diamondStorage().marginEscrow = MarginEscrow(_marginEscrow);
        diamondStorage().owner = _owner;
        ERC165MappingImplementation();
        vaultMappingImplementation();
    }

    /// @notice Transfer some margin deposit
    /// @param _sponsor user address who deposit to this escrow
    /// @param _reserve reserve address
    /// @param _amount deposit amount
    function depositMargin(
        address _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable nonReentrant onlyVoyager {
        VaultConfig memory vaultConfig = vaultFacet().getVaultConfig(_reserve);

        uint256 maxAllowedAmount = vaultConfig.maxMargin;
        uint256 depositedAmount = diamondStorage()
            .marginEscrow
            .getDepositAmount(_reserve);
        require(
            depositedAmount + _amount <= maxAllowedAmount,
            "Vault: deposit amount exceed"
        );

        uint256 minAllowedAmount = vaultConfig.minMargin;
        require(minAllowedAmount <= _amount, "Vault: deposit too small");

        diamondStorage().marginEscrow.deposit(_reserve, _sponsor, _amount);
    }

    /// @notice Redeem underlying reserve
    /// @param _sponsor sponsor address
    /// @param _reserve reserve address
    /// @param _amount redeem amount
    function redeemMargin(
        address payable _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable nonReentrant onlyVoyager {
        require(
            _amount <= getWithdrawableDepositInternal(_sponsor, _reserve),
            "Vault: cannot redeem more than withdrawable deposit amount"
        );
        diamondStorage().marginEscrow.withdraw(_reserve, _sponsor, _amount);
    }

    /// @return Returns the actual value that has been transferred
    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) external nonReentrant onlyVoyager returns (uint256) {
        return diamondStorage().marginEscrow.slash(_reserve, _to, _amount);
    }

    /// @notice Insert new NFT
    /// @param _erc721Addr NFT address
    /// @param _tokenId Token id
    function insertNFT(address _erc721Addr, uint256 _tokenId)
        external
        onlyVoyager
    {
        diamondStorage().nfts[_erc721Addr].insert(_tokenId, block.timestamp);
    }

    /// @notice Transfer nft out
    /// @param _erc721Addr NFT address
    /// @param _to whom to transfer
    /// @param _num Number of nfts to transfer
    function transferNFT(
        address _erc721Addr,
        address _to,
        uint256 _num
    ) external nonReentrant onlyVoyager {
        for (uint256 i = 0; i < _num; i++) {
            uint256 tokenId;
            uint256 timestamp;
            (tokenId, timestamp) = diamondStorage().nfts[_erc721Addr].delMin();
            IERC721(_erc721Addr).transferFrom(address(this), _to, tokenId);
        }
    }

    /// @notice Should return whether the signature provided is valid for the provided data
    /// @param hash      Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        address sender = recoverSigner(hash, signature);
        console.log("sender: ", sender);
        if (diamondStorage().owner == sender) {
            return 0x1626ba7e;
        }
        return 0xffffffff;
    }

    /************************************** View Functions **************************************/

    /// @notice Returns true if this contract implements the interface defined by
    /// `interfaceId`. See the corresponding
    ///  https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    /// to learn more about how these ids are created.
    ///
    /// This function call must use less than 30 000 gas.
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return diamondStorage().supportedInterfaces[interfaceId];
    }

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function diamondStorage()
        internal
        pure
        returns (VaultStorageV1 storage ds)
    {
        // Specifies a random position in contract storage
        // This can be done with a keccak256 hash of a unique string as is
        // done here or other schemes can be used such as this:
        // bytes32 storagePosition = keccak256(abi.encodePacked(ERC1155.interfaceId, ERC1155.name, address(this)));
        bytes32 storagePosition = keccak256("finance.voyage.vault.v1.storage");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }

    function addressResolver() internal view returns (IAddressResolver) {
        return Voyager(payable(voyager)).addressResolver();
    }

    function aclManager() internal view returns (IACLManager) {
        return IACLManager(addressResolver().getAclManager());
    }

    function loanFacet() internal view returns (LoanFacet) {
        return LoanFacet(voyager);
    }

    function vaultFacet() internal view returns (VaultFacet) {
        return VaultFacet(voyager);
    }

    function getCurrentMargin(address _reserve)
        external
        view
        returns (uint256)
    {
        return diamondStorage().marginEscrow.getDepositAmount(_reserve);
    }

    function getActualSecurityDeposit(address _reserve)
        public
        view
        returns (uint256)
    {
        return
            ERC20(_reserve).balanceOf(address(diamondStorage().marginEscrow));
    }

    function getWithdrawableDeposit(address _sponsor, address _reserve)
        external
        view
        returns (uint256)
    {
        return getWithdrawableDepositInternal(_sponsor, _reserve);
    }

    /**
     * @dev Get MarginEscrow contract address
     * @return address
     **/
    function getMarginEscrowAddress() external view returns (address) {
        return address(diamondStorage().marginEscrow);
    }

    function getTotalNFTNumbers(address _erc721Addr)
        external
        view
        returns (uint256)
    {
        return diamondStorage().nfts[_erc721Addr].currentSize;
    }

    /************************************** Internal Functions **************************************/

    /// @notice Recover the signer of hash, assuming it's an EOA account
    /// @dev Only for EthSign signatures
    /// @param _hash       Hash of message that was signed
    /// @param _signature  Signature encoded as (bytes32 r, bytes32 s, uint8 v)
    function recoverSigner(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address signer)
    {
        require(
            _signature.length == 65,
            "SignatureValidator#recoverSigner: invalid signature length"
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        //
        // Source OpenZeppelin
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert(
                "SignatureValidator#recoverSigner: invalid signature 's' value"
            );
        }

        if (v != 27 && v != 28) {
            revert(
                "SignatureValidator#recoverSigner: invalid signature 'v' value"
            );
        }

        // Recover ECDSA signer
        signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ),
            v,
            r,
            s
        );

        // Prevent signer from being 0x0
        require(
            signer != address(0x0),
            "SignatureValidator#recoverSigner: INVALID_SIGNER"
        );

        return signer;
    }

    function ERC165MappingImplementation() internal {
        diamondStorage().supportedInterfaces[
            this.supportsInterface.selector
        ] = true;
    }

    function vaultMappingImplementation() internal {
        mapping(bytes4 => bool) storage supportedInterfaces = diamondStorage()
            .supportedInterfaces;
        supportedInterfaces[this.depositMargin.selector] = true;
        supportedInterfaces[this.redeemMargin.selector] = true;
        supportedInterfaces[this.slash.selector] = true;
        supportedInterfaces[this.insertNFT.selector] = true;
        supportedInterfaces[this.transferNFT.selector] = true;
    }

    function getWithdrawableDepositInternal(address _sponsor, address _reserve)
        internal
        view
        returns (uint256)
    {
        VaultConfig memory vaultConfig = vaultFacet().getVaultConfig(_reserve);
        uint256 marginRequirement = vaultConfig.marginRequirement;
        uint256 principal;
        uint256 interest;
        (principal, interest) = loanFacet().getVaultDebt(
            _reserve,
            address(this)
        );

        uint256 totalDebt = principal.add(interest);
        uint256 eligibleAmount = diamondStorage().marginEscrow.eligibleAmount(
            _reserve,
            _sponsor
        );
        uint256 withdrawableAmount = eligibleAmount -
            totalDebt.wadToRay().rayMul(marginRequirement).rayToWad();

        return withdrawableAmount;
    }
}

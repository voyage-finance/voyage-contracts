// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SecurityDepositEscrow} from "./SecurityDepositEscrow.sol";
import {AddressResolver} from "../infra/AddressResolver.sol";
import {Voyager} from "../Voyager.sol";
import {VaultManager} from "./VaultManager.sol";
import {LoanManagerProxy} from "../loan/LoanManagerProxy.sol";
import {SecurityDepositToken} from "../../tokenization/SecurityDepositToken.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {ILoanManager} from "../../interfaces/ILoanManager.sol";
import {IAddressResolver} from "../../interfaces/IAddressResolver.sol";
import {IVaultManagerProxy} from "../../interfaces/IVaultManagerProxy.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {PriorityQueue} from "../../libraries/logic/PriorityQueue.sol";

contract Vault is ReentrancyGuard, IVault, IERC1271, IERC165 {
    using WadRayMath for uint256;
    using SafeMath for uint256;
    using PriorityQueue for DataTypes.Heap;

    // about to remove or refactor
    IAddressResolver addressResolver;
    IACLManager aclManager;

    struct VaultStorageV1 {
        bool initialized;
        address owner;
        SecurityDepositEscrow securityDepositEscrow;
        SecurityDepositToken securityDepositToken;
        mapping(address => DataTypes.Heap) nfts;
        /// @dev You must not set element 0xffffffff to true
        mapping(bytes4 => bool) supportedInterfaces;
    }

    modifier onlyLoanManager() {
        require(
            aclManager.isLoanManager(msg.sender),
            "Not loan manager contract"
        );
        _;
    }

    modifier onlyVaultManager() {
        require(
            aclManager.isVaultManagerContract(msg.sender),
            "Not vault manager contract"
        );
        _;
    }

    modifier onlyVaultManagerContract() {
        require(
            aclManager.isLoanManagerContract(msg.sender),
            "Not loan manager"
        );
        _;
    }

    function initialize(
        address _voyager,
        SecurityDepositEscrow _securityDepositEscrow
    ) external {
        if (!diamondStorage().initialized) {
            addressResolver = Voyager(payable(_voyager)).addressResolver();
            aclManager = IACLManager(addressResolver.getAclManager());
            diamondStorage().securityDepositEscrow = _securityDepositEscrow;
            diamondStorage().initialized = true;
            ERC165MappingImplementation();
            vaultMappingImplementation();
        }
    }

    function initSecurityDepositToken(address _reserve)
        external
        onlyVaultManager
    {
        require(
            address(diamondStorage().securityDepositToken) == address(0),
            "Vault: security deposit token has been initialized"
        );
        ERC20 token = ERC20(_reserve);
        diamondStorage().securityDepositToken = new SecurityDepositToken(
            _reserve,
            token.decimals(),
            token.name(),
            token.symbol()
        );
    }

    /// @notice Transfer some deposit security
    /// @param _sponsor user address who deposit to this escrow
    /// @param _reserve reserve address
    /// @param _amount deposit amount
    function depositSecurity(
        address _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable nonReentrant onlyVaultManager {
        address vmp = addressResolver.getVaultManagerProxy();
        IVaultManagerProxy vaultManagerProxy = IVaultManagerProxy(vmp);
        DataTypes.VaultConfig memory vaultConfig = vaultManagerProxy
            .getVaultConfig(_reserve);

        // check max security deposit amount for this _reserve
        uint256 maxAllowedAmount = vaultConfig.maxSecurityDeposit;
        uint256 depositedAmount = diamondStorage()
            .securityDepositEscrow
            .getDepositAmount(_reserve);
        require(
            depositedAmount + _amount < maxAllowedAmount,
            "Vault: deposit amount exceed"
        );

        // check min security deposit amount for this _reserve
        uint256 minAllowedAmount = vaultConfig.minSecurityDeposit;
        require(minAllowedAmount <= _amount, "Vault: deposit too small");

        diamondStorage().securityDepositEscrow.deposit(
            _reserve,
            _sponsor,
            _amount
        );
        diamondStorage().securityDepositToken.mintOnDeposit(_sponsor, _amount);
    }

    /// @notice Redeem underlying reserve
    /// @param _sponsor sponsor address
    /// @param _reserve reserve address
    /// @param _amount redeem amount
    function redeemSecurity(
        address payable _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable nonReentrant onlyVaultManager {
        require(
            _amount <= getWithdrawableDepositInternal(_sponsor, _reserve),
            "Vault: cannot redeem more than withdrawable deposit amount"
        );
        diamondStorage().securityDepositEscrow.withdraw(
            _reserve,
            _sponsor,
            underlyingBalanceInternal(_sponsor, _reserve)
        );
        diamondStorage().securityDepositToken.burnOnRedeem(_sponsor, _amount);
    }

    /// @return Returns the actual value that has been transferred
    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) external nonReentrant onlyVaultManager returns (uint256) {
        return
            diamondStorage().securityDepositEscrow.slash(
                _reserve,
                _to,
                _amount
            );
    }

    /// @notice Insert new NFT
    /// @param _erc721Addr NFT address
    /// @param _tokenId Token id
    function insertNFT(address _erc721Addr, uint256 _tokenId)
        external
        onlyVaultManager
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
    ) external nonReentrant onlyLoanManager {
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

    function getCurrentSecurityDeposit(address _reserve)
        external
        view
        returns (uint256)
    {
        return
            diamondStorage().securityDepositEscrow.getDepositAmount(_reserve);
    }

    function getActualSecurityDeposit(address _reserve)
        public
        view
        returns (uint256)
    {
        return
            ERC20(_reserve).balanceOf(
                address(diamondStorage().securityDepositEscrow)
            );
    }

    function getWithdrawableDeposit(address _sponsor, address _reserve)
        external
        view
        returns (uint256)
    {
        return getWithdrawableDepositInternal(_sponsor, _reserve);
    }

    function underlyingBalance(address _sponsor, address _reserve)
        external
        view
        returns (uint256)
    {
        return underlyingBalanceInternal(_sponsor, _reserve);
    }

    function getSecurityDepositTokenAddress() external view returns (address) {
        return address(diamondStorage().securityDepositToken);
    }

    /**
     * @dev Get SecurityDepositEscrow contract address
     * @return address
     **/
    function getSecurityDepositEscrowAddress() external view returns (address) {
        return address(diamondStorage().securityDepositEscrow);
    }

    function getTotalNFTNumbers(address _erc721Addr)
        external
        view
        returns (uint256)
    {
        return diamondStorage().nfts[_erc721Addr].currentSize;
    }

    function getVersion() external view returns (string memory) {
        string memory version = "Vault 0.0.1";
        return version;
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
        supportedInterfaces[this.initSecurityDepositToken.selector] = true;
        supportedInterfaces[this.depositSecurity.selector] = true;
        supportedInterfaces[this.redeemSecurity.selector] = true;
        supportedInterfaces[this.slash.selector] = true;
        supportedInterfaces[this.insertNFT.selector] = true;
        supportedInterfaces[this.transferNFT.selector] = true;
    }

    function underlyingBalanceInternal(address _sponsor, address _reserve)
        internal
        view
        returns (uint256)
    {
        uint256 amountToRedeemInRay = diamondStorage()
            .securityDepositToken
            .balanceOf(_sponsor)
            .wadToRay()
            .rayDiv(
                diamondStorage().securityDepositToken.totalSupply().wadToRay()
            )
            .rayMul(getActualSecurityDeposit(_reserve).wadToRay());
        return amountToRedeemInRay.rayToWad();
    }

    function getWithdrawableDepositInternal(address _sponsor, address _reserve)
        internal
        view
        returns (uint256)
    {
        address vmp = addressResolver.getVaultManagerProxy();
        IVaultManagerProxy vaultManagerProxy = IVaultManagerProxy(vmp);
        DataTypes.VaultConfig memory vaultConfig = vaultManagerProxy
            .getVaultConfig(_reserve);

        uint256 securityRequirement = vaultConfig.securityDepositRequirement;
        uint256 principal;
        uint256 interest;
        (principal, interest) = ILoanManager(
            addressResolver.getLoanManagerProxy()
        ).getVaultDebt(_reserve, address(this));

        uint256 totalDebt = principal.add(interest);
        uint256 withdrawableAmount = diamondStorage()
            .securityDepositToken
            .balanceOf(_sponsor) -
            totalDebt.wadToRay().rayMul(securityRequirement).rayToWad();
        uint256 eligibleAmount = diamondStorage()
            .securityDepositEscrow
            .eligibleAmount(_reserve, _sponsor);
        if (eligibleAmount < withdrawableAmount) {
            withdrawableAmount = eligibleAmount;
        }
        return withdrawableAmount;
    }
}

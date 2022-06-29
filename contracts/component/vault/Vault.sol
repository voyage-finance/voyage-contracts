// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {MarginEscrow} from "./MarginEscrow.sol";
import {CreditEscrow} from "./CreditEscrow.sol";
import {Voyager} from "../Voyager.sol";
import {VaultFacet} from "../facets/VaultFacet.sol";
import {PeripheryPayments} from "../../libraries/utils/PeripheryPayments.sol";
import {LoanFacet} from "../facets/LoanFacet.sol";
import {VaultConfig, NFTInfo} from "../../libraries/LibAppStorage.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IMarginEscrow} from "../../interfaces/IMarginEscrow.sol";
import {IExternalAdapter} from "../../interfaces/IExternalAdapter.sol";
import {PriorityQueue, Heap} from "../../libraries/logic/PriorityQueue.sol";

contract Vault is
    ReentrancyGuard,
    Initializable,
    IVault,
    IERC1271,
    IERC165,
    IERC721Receiver,
    PeripheryPayments
{
    using WadRayMath for uint256;
    using SafeMath for uint256;
    using PriorityQueue for Heap;
    using SafeERC20 for IERC20;

    struct VaultStorageV1 {
        address owner;
        address voyager;
        // asset (ERC20) => escrow
        mapping(address => CreditEscrow) cescrow;
        mapping(address => address) escrow;
        // erc721 address => heap
        mapping(address => Heap) nfts;
        /// @dev You must not set element 0xffffffff to true
        mapping(bytes4 => bool) supportedInterfaces;
    }

    modifier onlyVoyager() {
        require(msg.sender == diamondStorage().voyager, "Not Voyager");
        _;
    }

    modifier onlyOwner() {
        VaultFacet vf = VaultFacet(diamondStorage().voyager);
        address vault = vf.getVaultAddr(msg.sender);
        require(vault == address(this), "Vault: not owner");
        _;
    }

    function initialize(address _voyager, address _owner) external initializer {
        diamondStorage().voyager = _voyager;
        diamondStorage().owner = _owner;
        ERC165MappingImplementation();
        vaultMappingImplementation();
    }

    function initAsset(address _asset) public onlyVoyager returns (address) {
        require(_asset != address(0), "_asset must be a valid address");
        VaultStorageV1 storage s = diamondStorage();
        require(
            address(s.escrow[_asset]) == address(0),
            "asset already initialised"
        );
        CreditEscrow _ce = new CreditEscrow();
        BeaconProxy proxy = new BeaconProxy(
            address(vaultFacet().marginEscrowBeacon()),
            abi.encodeWithSelector(
                IMarginEscrow(address(0)).initialize.selector,
                address(this),
                s.voyager,
                _asset
            )
        );
        address _me = address(proxy);
        require(_me != address(0), "failed to deploy margin escrow");
        s.escrow[_asset] = _me;
        s.cescrow[_asset] = _ce;
        // max approve escrow
        IERC20(_asset).safeApprove(address(_ce), type(uint256).max);
        IERC20(_asset).safeApprove(_me, type(uint256).max);
        return _me;
    }

    /// @notice Transfer some margin deposit
    /// @param _sponsor address of margin depositer
    /// @param _reserve reserve address
    /// @param _amount deposit amount
    function depositMargin(
        address _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable nonReentrant onlyVoyager {
        VaultConfig memory vaultConfig = vaultFacet().getVaultConfig(_reserve);
        IMarginEscrow me = marginEscrow(_reserve);
        require(address(me) != address(0), "Vault: asset not initialised");
        uint256 maxAllowedAmount = vaultConfig.maxMargin;
        uint256 depositedAmount = me.totalMargin();
        require(
            depositedAmount + _amount <= maxAllowedAmount,
            "Vault: deposit amount exceed"
        );
        uint256 minAllowedAmount = vaultConfig.minMargin;
        require(minAllowedAmount <= _amount, "Vault: deposit too small");
        pullToken(me.asset(), _amount, _sponsor, address(this));
        me.deposit(_amount, _sponsor);
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
        IMarginEscrow me = marginEscrow(_reserve);
        require(address(me) != address(0), "Vault: asset not initialised");
        me.withdraw(_amount, _sponsor, _sponsor);
    }

    /// @return Returns the actual value that has been transferred
    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) external nonReentrant onlyVoyager returns (uint256) {
        IMarginEscrow me = marginEscrow(_reserve);
        return me.slash(_amount, _to);
    }

    /// @notice To accept external calls from authorised client, used for pursing NFT or doing approve etc.
    function callExternal(Call[] calldata calls)
        external
        onlyOwner
        returns (bytes[] memory)
    {
        bytes[] memory returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            returnData[i] = callExternal(calls[i].target, calls[i].callData);
        }
        return returnData;
    }

    function callExternal(address target, bytes calldata data)
        internal
        returns (bytes memory)
    {
        VaultFacet vf = VaultFacet(diamondStorage().voyager);
        bytes4 selector = bytes4(data[0:4]);
        bytes memory args = data[4:];
        (
            address[] memory beforeTarget,
            bytes[] memory beforeData,
            address[] memory onSuccessTarget,
            bytes[] memory onSuccessData
        ) = vf.validate(target, selector, args);
        _call(beforeTarget, beforeData);
        (bool success, bytes memory ret) = target.call(data);
        require(success);
        _call(onSuccessTarget, onSuccessData);
        return ret;
    }

    function _call(address[] memory target, bytes[] memory data) internal {
        for (uint256 i = 0; i < target.length; i++) {
            if (target[i] != address(0)) {
                (bool success, bytes memory ret) = target[i].call(data[i]);
                require(success, "invalid before call");
            }
        }
    }

    /// @notice refund transferred amount back to escrow if there is any
    /// @param _target To find adapter
    /// @param _reserve Reserve address
    /// @param _amountBefore Balance before transferring happen to buy nft etc.
    function refund(
        address _target,
        address _reserve,
        uint256 _amountBefore
    ) external {
        require(msg.sender == address(this), "Vault#refund: invalid caller");
        uint256 depositAmount = _amountBefore.sub(
            IERC20(_reserve).balanceOf(address(this))
        );
        address escrow = address(diamondStorage().cescrow[_reserve]);
        require(escrow != address(0), "Vault#refund: asset not initialised");
        if (depositAmount != 0) {
            IERC20(_reserve).safeTransfer(escrow, depositAmount);
        }
    }

    function withdrawNFT(
        address _reserve,
        address _erc721Addr,
        uint256 _tokenId
    ) external onlyOwner {
        VaultFacet vf = VaultFacet(diamondStorage().voyager);
        NFTInfo memory nftInfo = vf.getNFTInfo(_erc721Addr, _tokenId);

        // 1. check if paid amount >= purchased price
        LoanFacet lf = LoanFacet(diamondStorage().voyager);
        (uint256 totalPaid, uint256 totalRedeemed) = lf.getTotalPaidAndRedeemed(
            _reserve,
            address(this)
        );
        require(
            totalPaid >= totalRedeemed,
            "Vault: invalid total paid and redeemed"
        );
        uint256 availableAmount = totalPaid.sub(totalRedeemed);
        require(availableAmount >= nftInfo.price, "Vault: invalid withdrawal");
        lf.increaseTotalRedeemed(_reserve, address(this), nftInfo.price);

        // 2. remove from heap
        diamondStorage().nfts[_erc721Addr].del(_tokenId, nftInfo.timestamp);

        // 3. transfer nft out
        IERC721(_erc721Addr).transferFrom(address(this), msg.sender, _tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        // todo check nft address
        diamondStorage().nfts[msg.sender].insert(tokenId, block.timestamp);
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

    function withdrawRewards(
        address _reserve,
        address _receiver,
        uint256 _amount
    ) external onlyOwner {
        require(
            IERC20(_reserve).balanceOf(address(this)) >= _amount,
            "Vault: fund not enough"
        );
        IERC20(_reserve).safeTransfer(_receiver, _amount);
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

    /// @notice Returns the margin escrow for a given asset supported by the Vault
    /// @dev If the returned address is 0x0, the asset is not supported
    /// @param _asset address of the underlying ERC20 being escrowed
    /// @return IMarginEscrow
    function marginEscrow(address _asset) public view returns (IMarginEscrow) {
        return IMarginEscrow(diamondStorage().escrow[_asset]);
    }

    function creditEscrow(address _asset) external view returns (address) {
        return address(diamondStorage().cescrow[_asset]);
    }

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

    function loanFacet() internal view returns (LoanFacet) {
        return LoanFacet(diamondStorage().voyager);
    }

    function vaultFacet() internal view returns (VaultFacet) {
        return VaultFacet(diamondStorage().voyager);
    }

    function getCurrentMargin(address _reserve)
        external
        view
        returns (uint256)
    {
        return marginEscrow(_reserve).totalMargin();
    }

    function getActualSecurityDeposit(address _reserve)
        public
        view
        returns (uint256)
    {
        return IERC20(_reserve).balanceOf(address(marginEscrow(_reserve)));
    }

    function withdrawableMargin(address _reserve, address _user)
        external
        view
        returns (uint256)
    {
        return marginEscrow(_reserve).withdrawableMargin(_user);
    }

    function totalWithdrawableMargin(address _reserve)
        external
        view
        returns (uint256)
    {
        return marginEscrow(_reserve).totalWithdrawableMargin();
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
        supportedInterfaces[this.transferNFT.selector] = true;
    }

    function totalDebt(address _reserve) external view returns (uint256 total) {
        uint256 principal;
        uint256 interest;
        (principal, interest) = loanFacet().getVaultDebt(
            _reserve,
            address(this)
        );
        total = principal.add(interest);
    }

    function marginRequirement(address _reserve)
        external
        view
        returns (uint256)
    {
        VaultConfig memory vc = vaultFacet().getVaultConfig(_reserve);
        return vc.marginRequirement;
    }
}

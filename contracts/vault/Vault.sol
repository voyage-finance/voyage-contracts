// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ConfigurationFacet} from "../voyage/facets/ConfigurationFacet.sol";
import {IVaultFacet} from "../voyage/interfaces/IVaultFacet.sol";
import {SecurityFacet} from "../voyage/facets/SecurityFacet.sol";
import {IWETH9} from "../shared/interfaces/IWETH9.sol";

struct VaultStorageV1 {
    address voyage;
    address user;
    address weth;
    // subvault array, for retrieval by DataProviderFacet and client-side enumeration
    address[] subvaults;
    // mapping of subvault to owner
    mapping(address => address) subvaultOwnerIndex;
    // mapping of owner to subvault
    mapping(address => address) ownerSubvaultIndex;
    // mapping of subvault => paused status
    mapping(address => bool) subvaultStatusIndex;
    mapping(address => uint256[]) tokenSet;
    // mapping of erc721 address to mapping of tokenId to custody information
    // to save storage space, only store this data if the token is transferred out of the Vault (i.e., to a Subvault or external contract)
    mapping(address => mapping(uint256 => CustodyData)) custodyIndex;
}

struct CustodyData {
    // the "owner" of the token -- must be Vault or a Subvault.
    address owner;
    // the current holder of the token, e.g., battle game.
    address custodian;
}

library LibVaultStorage {
    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function ds() internal pure returns (VaultStorageV1 storage ds) {
        // Set the position of our struct in contract storage
        bytes32 storagePosition = keccak256("diamond.storage.vault.voyage");
        assembly {
            ds.slot := storagePosition
        }
    }
}

interface IVault {
    event GasRefunded(
        address _paymaster,
        address _dst,
        uint256 _amount,
        uint256 _shortfall,
        bytes _result
    );

    event Execute(address _vault, address _target, bytes _data);

    function initialize(
        address _voyage,
        address _user,
        address _weth
    ) external;

    function execute(
        bytes calldata _data,
        address _target,
        uint256 _value
    ) external payable;

    function refundGas(uint256 _amount, address _dst) external;

    function onERC721Transferred(
        address _collection,
        uint256 _tokenId,
        address _src,
        address _dst
    ) external;

    function collectionInitialized(address _collection)
        external
        view
        returns (bool);
}

contract Vault is Initializable, IERC1271, IVault {
    bytes internal constant EMPTY_BYTES = "";

    modifier onlyPaymaster() {
        require(_isPaymaster(msg.sender), "Only paymaster allowed");
        _;
    }

    modifier onlyAuthorised() {
        SecurityFacet sf = SecurityFacet(LibVaultStorage.ds().voyage);
        require(
            sf.isAuthorised(msg.sender, address(this), msg.sig),
            "unauthorised"
        );
        _;
    }

    function initialize(
        address _voyage,
        address _user,
        address _weth
    ) public initializer {
        LibVaultStorage.ds().voyage = _voyage;
        LibVaultStorage.ds().user = _user;
        LibVaultStorage.ds().weth = _weth;
        IERC20(_weth).approve(_voyage, type(uint256).max);
    }

    function execute(
        bytes calldata _data,
        address _target,
        uint256 _value
    ) external payable onlyAuthorised {
        (bool success, bytes memory ret) = _target.call{value: _value}(_data);
        if (!success) {
            revert ExternalCallFailed(bytesToHex(ret));
        }
        emit Execute(address(this), _target, _data);
    }

    function refundGas(uint256 _amount, address _dst) external onlyPaymaster {
        uint256 amountRefundable = _amount;
        uint256 ethBal = address(this).balance;
        // we need to unwrap some WETH in this case.
        if (ethBal < _amount) {
            IWETH9 weth9 = IWETH9(LibVaultStorage.ds().weth);
            uint256 balanceWETH9 = weth9.balanceOf(address(this));
            uint256 toUnwrap = _amount - ethBal;
            // this should not happen, but if it does, we should take what we can instead of reverting
            if (toUnwrap > balanceWETH9) {
                weth9.withdraw(balanceWETH9);
                amountRefundable = amountRefundable - (toUnwrap - balanceWETH9);
            } else {
                weth9.withdraw(toUnwrap);
            }
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = _dst.call{
            value: amountRefundable
        }(EMPTY_BYTES);
        if (!success) {
            revert GasRefundFailed(_dst);
        }
        emit GasRefunded(
            _getPaymaster(),
            _dst,
            amountRefundable,
            _amount - amountRefundable,
            result
        );
    }

    /// @notice Approves Voyage to manage WETH for the Vault
    /// @dev Anyone may call this function
    function approveVoyage() public {
        VaultStorageV1 storage ds = LibVaultStorage.ds();
        IERC20(ds.weth).approve(ds.voyage, type(uint256).max);
    }

    function collectionInitialized(address _collection)
        external
        view
        returns (bool)
    {
        IVaultFacet vf = IVaultFacet(LibVaultStorage.ds().voyage);
        return vf.collectionInitialized(_collection);
    }

    function onERC721Transferred(
        address _collection,
        uint256 _tokenId,
        address _src,
        address _dst
    ) external {
        if (
            msg.sender != address(this) &&
            LibVaultStorage.ds().subvaultOwnerIndex[msg.sender] == address(0)
        ) {
            revert InvalidTransfer("invalid sender");
        }
        if (
            LibVaultStorage.ds().custodyIndex[_collection][_tokenId].owner !=
            address(0)
        ) {
            revert InvalidTransfer("invalid token id");
        }
        LibVaultStorage.ds().custodyIndex[_collection][_tokenId].owner = _src;
        LibVaultStorage.ds().tokenSet[_collection].push(_tokenId);
    }

    /// @notice Called by erc721 contract or sub vaults
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4 ret) {
        return this.onERC721Received.selector;
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
        if (LibVaultStorage.ds().user == sender) {
            return 0x1626ba7e;
        }
        return 0xffffffff;
    }

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
        signer = ecrecover(_hash, v, r, s);

        // Prevent signer from being 0x0
        require(
            signer != address(0x0),
            "SignatureValidator#recoverSigner: INVALID_SIGNER"
        );

        return signer;
    }

    receive() external payable {}

    /// @notice Get sub vault address of a specific user
    /// @param _owner The address of the user
    function getSubvaultOf(address _owner) public view returns (address) {
        return LibVaultStorage.ds().ownerSubvaultIndex[_owner];
    }

    /// @notice Get sub vault's address
    /// @param _subvault The address of the subvault
    function getSubvaultStatus(address _subvault) public view returns (bool) {
        return LibVaultStorage.ds().subvaultStatusIndex[_subvault];
    }

    /// @notice Get token status
    /// @param _collection The address of the ERC721 contract
    /// @param _tokenId Token id
    function getTokenStatus(address _collection, uint256 _tokenId)
        public
        view
        returns (CustodyData memory)
    {
        return LibVaultStorage.ds().custodyIndex[_collection][_tokenId];
    }

    /// @notice Get token list owned by this vault
    /// @param _collection The address of the ERC721 contract
    function getTokensOwned(address _collection)
        public
        view
        returns (uint256[] memory)
    {
        return LibVaultStorage.ds().tokenSet[_collection];
    }

    function _getPaymaster() internal view returns (address) {
        return
            ConfigurationFacet(LibVaultStorage.ds().voyage).getPaymasterAddr();
    }

    function _isPaymaster(address _src) internal view returns (bool) {
        return _src == _getPaymaster();
    }

    function bytesToHex(bytes memory buffer)
        internal
        pure
        returns (string memory)
    {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }

    error GasRefundFailed(address _paymaster);
    error ExternalCallFailed(string);
    error UnAuthorised();
    error InvalidSubvaultAddress(address subvault);
    error InvalidTransfer(string reason);
}

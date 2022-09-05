// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {DSRoles} from "../auth/DSRoles.sol";
import {DSGuard} from "../auth/DSGuard.sol";
import {LibSecurity} from "./LibSecurity.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";
import {IDiamondCut} from "../../shared/diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../../shared/diamond/interfaces/IDiamondLoupe.sol";
import {DiamondCutFacet} from "../../shared/diamond/facets/DiamondCutFacet.sol";
import {IWETH9} from "../../shared/facets/PaymentsFacet.sol";

enum Tranche {
    JUNIOR,
    SENIOR
}

struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    uint256 currentBorrowRate;
    //the decimals of the reserve asset
    uint256 decimals;
    address interestRateStrategyAddress;
    address juniorDepositTokenAddress;
    address seniorDepositTokenAddress;
    uint40 juniorLastUpdateTimestamp;
    uint40 seniorLastUpdateTimestamp;
    address currency;
    UpgradeableBeacon priceOracle;
    bool initialized;
}

struct ReserveConfigurationMap {
    //bit 0-15: liquidation bonus (uint16)
    //bit 16-23: decimals (uint8)
    //bit 24: reserve is active
    //bit 25: reserve is frozen
    //bit 26: borrowing is enabled
    //bit 27: reserved
    //bit 28-63: min margin (uint36)
    //bit 64-99: max margin (uint36)
    //bit 100-115: margin requirement (uint16)
    //bit 116-131: income ratio (uint16)
    //bit 132-139: instalment interval (uint8)
    //bit 140-155: loan term (uint16)
    //bit 156-163: repayment grace period (uint8)
    //bit 164-255: unused
    uint256 data;
}

struct PMT {
    uint256 principal;
    uint256 interest;
    uint256 pmt;
}

struct RepaymentData {
    uint256 principal;
    uint256 interest;
    // principal + interest
    uint256 total;
    uint40 paidAt;
    bool isLiquidated;
}

struct Loan {
    uint256 principal;
    uint256 interest;
    // the total intended length of the loan in seconds - e.g., 90 days
    uint40 term;
    // the repayment interval - e.g., 30 days
    uint40 epoch;
    // number of instalments, term / epoch
    uint40 nper;
    // cache of reserve data
    uint256 incomeRatio;
    // the amount to be repaid per instalment (principal + interest)
    PMT pmt;
    // the borrow rate of this loan
    uint256 apr;
    uint40 borrowAt;
    // next due data
    uint40 nextPaymentDue;
    // principal paid
    uint256 totalPrincipalPaid;
    // interest paid
    uint256 totalInterestPaid;
    RepaymentData[] repayments;
    // size of repayments
    uint40 paidTimes;
    uint256[] collateral;
}

struct LoanList {
    uint40 head;
    uint40 tail;
}

struct BorrowData {
    uint40 paidLoanNumber;
    // next draw down number
    uint40 nextLoanNumber;
    uint256 totalPrincipal;
    uint256 totalInterest;
    uint256 mapSize;
    mapping(uint256 => Loan) loans;
}

struct RepayRecord {
    uint256 repaidTimes;
    uint256 defaultTimes;
}

struct BorrowState {
    uint256 totalDebt;
    uint256 totalInterest;
    uint256 totalSeniorInterest;
    uint256 totalJuniorInterest;
    uint256 avgBorrowRate;
    mapping(address => RepayRecord) repayRecord;
}

struct ProtocolFee {
    address treasuryAddress;
    uint40 takeRate; // express in Ray
}

struct Authorisation {
    DSRoles rbac;
    DSGuard acl;
}

struct NFTInfo {
    bool isCollateral; // this determines whether the NFT can be transferred out of the Vault.
    address collection;
    uint256 tokenId;
    address currency; // record what currency was used to pay
    uint256 price; // price in ETH
}

struct ERC721AssetInfo {
    address marketplace;
    address erc20Addr;
}

struct UpgradeParam {
    mapping(address => mapping(bytes4 => address)) existingSelectorFacetMap;
    mapping(address => bytes4[]) existingSelectors;
    mapping(address => mapping(bytes4 => bool)) newSelectorSet;
    mapping(address => bytes4[]) newSelectors;
    mapping(address => IDiamondCut.FacetCut[]) facetCuts;
    mapping(address => uint256) facetCutSize;
    mapping(uint256 => bytes4[]) selectorsAdded;
    mapping(uint256 => bytes4[]) selectorsReplaced;
    mapping(uint256 => bytes4[]) selectorsRemoved;
}

struct DiamondFacet {
    address diamondCutFacet;
    address diamondLoupeFacet;
    address ownershipFacet;
}

struct MarketPlaceData {
    address adapterAddr;
}

struct AppStorage {
    /* -------------------------------- plumbing -------------------------------- */
    mapping(bytes32 => address) _addresses;
    /* -------------------------------- liquidity ------------------------------- */
    UpgradeableBeacon seniorDepositTokenBeacon;
    UpgradeableBeacon juniorDepositTokenBeacon;
    // mapping of collection address to reserve data
    mapping(address => ReserveData) _reserveData;
    // List of reserves as a map (reserveId => reserve)
    mapping(uint256 => address) _reserveList;
    uint16 _reservesCount;
    IWETH9 WETH9;
    /* ---------------------------------- debt ---------------------------------- */
    // collection => currency => vault => data
    mapping(address => mapping(address => mapping(address => BorrowData))) _borrowData;
    mapping(address => mapping(address => BorrowState)) _borrowState;
    bool _paused;
    /* ---------------------------------- vault --------------------------------- */
    UpgradeableBeacon subVaultBeacon;
    UpgradeableBeacon vaultBeacon;
    DiamondFacet diamondFacet;
    IVaultFactory vaultFactory;
    address[] vaults;
    // mapping of vault owner to vault instance address
    mapping(address => address) vaultMap;
    // marketplace address => marketplace type
    mapping(address => MarketPlaceData) marketPlaceData;
    // collection => tokenId => info
    mapping(address => mapping(uint256 => NFTInfo)) nftIndex;
    /* ---------------------------------- security --------------------------------- */
    Authorisation auth;
    address trustedForwarder; // GSN IERC2771 receiver
    address paymaster; // VoyagePaymaster address
    /* --------------------------------- protocol fee ------------------------------ */
    ProtocolFee protocolFee;
    /* ---------------------------------- helper --------------------------------- */
    // mapping of sender address to helper maps, need to clear after computing
    UpgradeParam upgradeParam;
}

library LibAppStorage {
    function ds() internal pure returns (AppStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.voyage");
        assembly {
            ds.slot := storagePosition
        }
    }

    function cleanUpgradeParam() internal {
        UpgradeParam storage s = ds().upgradeParam;
        for (uint256 i = 0; i < s.existingSelectors[msg.sender].length; ) {
            delete s.existingSelectorFacetMap[msg.sender][
                s.existingSelectors[msg.sender][i]
            ];
            unchecked {
                ++i;
            }
        }
        delete s.existingSelectors[msg.sender];

        for (uint256 i = 0; i < s.newSelectors[msg.sender].length; ) {
            delete s.newSelectorSet[msg.sender][s.newSelectors[msg.sender][i]];
            unchecked {
                ++i;
            }
        }
        delete s.newSelectors[msg.sender];

        delete s.facetCuts[msg.sender];
        delete s.facetCutSize[msg.sender];
    }
}

contract Storage {
    modifier whenPaused() {
        require(LibAppStorage.ds()._paused, "Pausable: not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!LibAppStorage.ds()._paused, "Pausable: paused");
        _;
    }

    modifier authorised() {
        require(auth(), "call is not authorised");
        _;
    }

    function auth() internal view returns (bool) {
        return
            LibSecurity.isAuthorisedInbound(
                LibAppStorage.ds().auth,
                _msgSender(),
                msg.sig
            );
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address ret) {
        if (
            msg.data.length >= 20 && LibSecurity.isTrustedForwarder(msg.sender)
        ) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal view virtual returns (bytes calldata ret) {
        if (
            msg.data.length >= 20 && LibSecurity.isTrustedForwarder(msg.sender)
        ) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

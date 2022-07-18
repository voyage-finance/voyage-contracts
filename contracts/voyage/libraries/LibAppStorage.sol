// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {DSRoles} from "../auth/DSRoles.sol";
import {DSGuard} from "../auth/DSGuard.sol";
import {LibSecurity} from "./LibSecurity.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Snapshot} from "../interfaces/IDiamondVersionFacet.sol";
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
    // for calculating overall interested accumulated
    // then split it into two indexs base on two allocations
    uint256 currentOverallLiquidityRate;
    uint256 currentJuniorLiquidityRate;
    uint256 currentSeniorLiquidityRate;
    uint256 currentBorrowRate;
    // Expressed in ray
    uint256 marginRequirement;
    //the decimals of the reserve asset
    uint256 decimals;
    address interestRateStrategyAddress;
    address loanStrategyAddress;
    address juniorDepositTokenAddress;
    address seniorDepositTokenAddress;
    uint40 juniorLastUpdateTimestamp;
    uint40 seniorLastUpdateTimestamp;
    // Expressed in basis point
    uint256 optimalTrancheRatio;
    uint256 currentIncomeRatio;
    uint256 optimalIncomeRatio;
    address nftAddress;
    address priceOracle;
    bool initialized;
}

struct ReserveConfigurationMap {
    //bit 0-15: Liquidate bonus
    //bit 16-23: Decimals
    //bit 24: Reserve is active
    //bit 25: reserve is frozen
    //bit 26: borrowing is enabled
    //bit 27-30: reserved
    //bit 31-46: reserve factor
    //bit 47-62: lock up period in seconds
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
    uint256 term;
    // the repayment interval - e.g., 30 days
    uint256 epoch;
    // number of instalments, term / epoch
    uint256 nper;
    // the amount to be repaid per instalment (principal + interest)
    PMT pmt;
    // the borrow rate of this loan
    uint256 apr;
    uint256 borrowAt;
    // next due data
    uint256 nextPaymentDue;
    // principal paid
    uint256 totalPrincipalPaid;
    // interest paid
    uint256 totalInterestPaid;
    RepaymentData[] repayments;
    // size pf repayments
    uint256 paidTimes;
}

struct LoanList {
    uint256 head;
    uint256 tail;
}

struct BorrowData {
    uint256 paidLoanNumber;
    // next draw down number
    uint256 nextLoanNumber;
    uint256 totalPrincipal;
    uint256 totalInterest;
    uint256 mapSize;
    mapping(uint256 => Loan) loans;
    uint256 totalPaid;
    uint256 totalRedeemed;
}

struct BorrowState {
    uint256 totalDebt;
    uint256 totalInterest;
    uint256 avgBorrowRate;
}

struct VaultConfig {
    uint256 minMargin;
    uint256 maxMargin;
    uint256 marginRequirement;
}

struct ProtocolFee {
    address treasuryAddress;
    uint256 cutRatio; // express in Ray
}

struct VaultData {
    uint256 totalDebt;
    LoanList loanList;
    uint256 totalMargin;
    uint256 withdrawableSecurityDeposit;
    uint256 creditLimit;
    uint256 spendableBalance;
    uint256 gav;
    uint256 ltv;
    uint256 healthFactor;
}

struct Authorisation {
    DSRoles rbac;
    DSGuard acl;
}

struct NFTInfo {
    uint256 price;
    uint256 timestamp;
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

struct AppStorage {
    /* -------------------------------- plumbing -------------------------------- */
    mapping(bytes32 => address) _addresses;
    /* -------------------------------- liquidity ------------------------------- */
    UpgradeableBeacon seniorDepositTokenBeacon;
    UpgradeableBeacon juniorDepositTokenBeacon;
    mapping(address => ReserveData) _reserves;
    // List of reserves as a map (reserveId => reserve)
    mapping(uint256 => address) _reserveList;
    uint16 _reservesCount;
    IWETH9 WETH9;
    /* ---------------------------------- debt ---------------------------------- */
    mapping(address => mapping(address => BorrowData)) _borrowData;
    mapping(address => BorrowState) _borrowState;
    bool _paused;
    /* ---------------------------------- vault --------------------------------- */
    UpgradeableBeacon marginEscrowBeacon;
    UpgradeableBeacon creditEscrowBeacon;
    UpgradeableBeacon subVaultBeacon;
    UpgradeableBeacon vaultBeacon;
    DiamondFacet diamondFacet;
    IVaultFactory vaultFactory;
    address[] vaults;
    // mapping of vault owner to vault instance address
    mapping(address => address) vaultMap;
    // mapping of underlying asset to vault configuration
    mapping(address => VaultConfig) vaultConfigMap;
    // mapping of marketplace to erc721 address
    // for validate onNFTReceived
    mapping(address => address) marketPlaceToAsset;
    mapping(address => ERC721AssetInfo) erc721AssetInfo;
    // erc721 address => token id => nft info
    mapping(address => mapping(uint256 => NFTInfo)) nftInfo;
    uint256 currentVersion;
    mapping(uint256 => Snapshot) snapshotMap;
    /* ---------------------------------- security --------------------------------- */
    Authorisation auth;
    /* --------------------------------- protocol fee ------------------------------ */
    ProtocolFee protocolFee;
    /* ---------------------------------- helper --------------------------------- */
    // mapping of sender address to helper maps, need to clear after computing
    UpgradeParam upgradeParam;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function cleanUpgradeParam() internal {
        UpgradeParam storage s = diamondStorage().upgradeParam;
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

contract Storage is Context {
    AppStorage internal s;

    modifier whenPaused() {
        require(s._paused, "Pausable: not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!s._paused, "Pausable: paused");
        _;
    }

    modifier authorised() {
        require(auth(), "call is not authorised");
        _;
    }

    function auth() internal view returns (bool) {
        return LibSecurity.isAuthorisedInbound(s.auth, msg.sender, msg.sig);
    }

    function computeSnapshotChecksum(Snapshot memory snapshot)
        internal
        view
        returns (bytes32)
    {
        bytes memory data;
        for (uint256 i = 0; i < snapshot.facets.length; ) {
            IDiamondLoupe.Facet memory facet = snapshot.facets[i];
            data = bytes.concat(data, abi.encodePacked(facet.facetAddress));
            for (uint256 j = 0; j < facet.functionSelectors.length; j++) {
                data = bytes.concat(data, facet.functionSelectors[j]);
            }
            bytes32 facetCodeHash;
            address facetAddress = facet.facetAddress;
            assembly {
                facetCodeHash := extcodehash(facetAddress)
            }
            data = bytes.concat(data, facetCodeHash);
            unchecked {
                ++i;
            }
        }
        return keccak256(data);
    }

    function diamondCut(address vault) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 currentVersion = s.currentVersion;
        Snapshot memory snapshot = s.snapshotMap[currentVersion];
        bytes32 checksum = computeSnapshotChecksum(snapshot);
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](
            snapshot.facets.length
        );
        for (uint256 i = 0; i < snapshot.facets.length; ) {
            address facetAddr = snapshot.facets[i].facetAddress;
            bytes4[] memory selectors = snapshot.facets[i].functionSelectors;
            facetCuts[i].facetAddress = facetAddr;
            facetCuts[i].functionSelectors = selectors;
            facetCuts[i].action = IDiamondCut.FacetCutAction.Add;
            unchecked {
                ++i;
            }
        }
        DiamondCutFacet(vault).diamondCut(
            facetCuts,
            snapshot.init,
            snapshot.initArgs
        );
    }
}

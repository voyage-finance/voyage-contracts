// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IMarketPlaceAdapter, AssetInfo} from "../interfaces/IMarketPlaceAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

uint256 constant BasicOrder_basicOrderType_cdPtr = 0x124;

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,
    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,
    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,
    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,
    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,
    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,
    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,
    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,
    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,
    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,
    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,
    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,
    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,
    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,
    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,
    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,
    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,
    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,
    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,
    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,
    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,
    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,
    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,
    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

struct PurchaseParam {
    address vault;
    address seaport;
    bytes4 selector;
    bytes basicOrderParameters;
}

interface ConsiderationInterface {
    /**
     * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
     *         the native token for the given chain) as consideration for the
     *         order. An arbitrary number of "additional recipients" may also be
     *         supplied which will each receive native tokens from the fulfiller
     *         as consideration.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer must first approve this contract (or
     *                   their preferred conduit if indicated by the order) for
     *                   their offered ERC721 token to be transferred.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool fulfilled);
}

contract SeaportAdapter is IMarketPlaceAdapter {
    address public weth;

    constructor(address _weth) {
        weth = _weth;
    }

    function extractAssetInfo(bytes calldata _data)
        external
        pure
        returns (AssetInfo memory assetInfo)
    {
        (, BasicOrderParameters memory order) = _decode(_data);
        assetInfo.tokenId = order.offerIdentifier;
        assetInfo.assetPrice = order.considerationAmount;
        // Iterate over each additional recipient.
        for (uint256 i = 0; i < order.additionalRecipients.length; ) {
            assetInfo.assetPrice += order.additionalRecipients[i].amount;

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    function validate(bytes calldata _data) external pure returns (bool) {
        return _validate(_data);
    }

    function execute(bytes calldata _data)
        external
        pure
        returns (bytes memory)
    {
        if (!_validate(_data)) {
            revert("invalid data");
        }

        (bytes4 selector, BasicOrderParameters memory order) = _decode(_data);

        return abi.encodePacked(selector, abi.encode(order));
    }

    function _decode(bytes calldata _data)
        internal
        pure
        returns (bytes4 selector, BasicOrderParameters memory order)
    {
        selector = bytes4(_data[:4]);
        order = abi.decode(_data[4:], (BasicOrderParameters));
    }

    function _validate(bytes calldata _data) private pure returns (bool) {
        (bytes4 selector, BasicOrderParameters memory order) = _decode(_data);

        // bytes4(keccak256(fulfillBasicOrder()))
        // 0xfb0f3ee1
        if (
            selector !=
            ConsiderationInterface(address(0)).fulfillBasicOrder.selector
        ) {
            return false;
        }

        BasicOrderType basicOrderType = order.basicOrderType;

        BasicOrderRouteType route;

        // Utilize assembly to extract the basic order route.
        assembly {
            // Divide basicOrderType by four to derive the route.
            route := shr(2, basicOrderType)
        }

        if (route != BasicOrderRouteType.ETH_TO_ERC721) {
            return false;
        }

        if (order.offerAmount != 1) {
            return false;
        }

        if (order.considerationToken != address(0)) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IMarketPlaceAdapter} from "../interfaces/IMarketPlaceAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

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

    function extractAssetPrice(bytes calldata _data)
        external
        pure
        returns (uint256)
    {
        PurchaseParam memory param = _decode(_data);
        BasicOrderParameters memory basicOrderParameters = abi.decode(
            param.basicOrderParameters,
            (BasicOrderParameters)
        );
        return basicOrderParameters.considerationAmount;
    }

    function validate(bytes calldata _data) external view returns (bool) {
        return _validate(_data);
    }

    function execute(bytes calldata _data)
        external
        view
        returns (bytes memory)
    {
        if (!_validate(_data)) {
            revert("invalid data");
        }

        PurchaseParam memory param = _decode(_data);

        return abi.encodePacked(param.selector, param.basicOrderParameters);
    }

    function _decode(bytes calldata _data)
        internal
        pure
        returns (PurchaseParam memory)
    {
        PurchaseParam memory param;
        (
            param.vault,
            param.seaport,
            param.selector,
            param.basicOrderParameters
        ) = abi.decode(_data, (address, address, bytes4, bytes));
        return param;
    }

    function _validate(bytes calldata _data) private view returns (bool) {
        PurchaseParam memory param = _decode(_data);

        // bytes4(keccak256(fulfillBasicOrder()))
        // 0xfb0f3ee1
        if (
            param.selector !=
            ConsiderationInterface(address(0)).fulfillBasicOrder.selector
        ) {
            return false;
        }

        BasicOrderParameters memory basicOrderParameters = abi.decode(
            param.basicOrderParameters,
            (BasicOrderParameters)
        );

        if (
            (basicOrderParameters.basicOrderType !=
                BasicOrderType.ETH_TO_ERC721_FULL_OPEN) &&
            (basicOrderParameters.basicOrderType !=
                BasicOrderType.ETH_TO_ERC721_PARTIAL_OPEN) &&
            (basicOrderParameters.basicOrderType !=
                BasicOrderType.ETH_TO_ERC721_FULL_RESTRICTED) &&
            (basicOrderParameters.basicOrderType !=
                BasicOrderType.ETH_TO_ERC721_PARTIAL_RESTRICTED) &&
            (basicOrderParameters.basicOrderType !=
                BasicOrderType.ERC20_TO_ERC721_FULL_OPEN) &&
            (basicOrderParameters.basicOrderType !=
                BasicOrderType.ERC20_TO_ERC721_PARTIAL_OPEN) &&
            (basicOrderParameters.basicOrderType !=
                BasicOrderType.ERC20_TO_ERC721_FULL_RESTRICTED) &&
            (basicOrderParameters.basicOrderType !=
                BasicOrderType.ERC20_TO_ERC721_PARTIAL_RESTRICTED)
        ) {
            return false;
        }

        if (basicOrderParameters.offerAmount != 1) {
            return false;
        }

        if (
            (basicOrderParameters.basicOrderType ==
                BasicOrderType.ETH_TO_ERC721_FULL_OPEN) ||
            (basicOrderParameters.basicOrderType ==
                BasicOrderType.ETH_TO_ERC721_PARTIAL_OPEN) ||
            (basicOrderParameters.basicOrderType ==
                BasicOrderType.ETH_TO_ERC721_FULL_RESTRICTED) ||
            (basicOrderParameters.basicOrderType ==
                BasicOrderType.ETH_TO_ERC721_PARTIAL_RESTRICTED)
        ) {
            if (basicOrderParameters.considerationToken != address(0)) {
                return false;
            }
        }

        if (
            (basicOrderParameters.basicOrderType ==
                BasicOrderType.ERC20_TO_ERC721_FULL_OPEN) ||
            (basicOrderParameters.basicOrderType ==
                BasicOrderType.ERC20_TO_ERC721_PARTIAL_OPEN) ||
            (basicOrderParameters.basicOrderType ==
                BasicOrderType.ERC20_TO_ERC721_FULL_RESTRICTED) ||
            (basicOrderParameters.basicOrderType ==
                BasicOrderType.ERC20_TO_ERC721_PARTIAL_RESTRICTED)
        ) {
            if (basicOrderParameters.considerationToken != weth) {
                return false;
            }
        }

        if (
            IERC20(weth).allowance(param.vault, param.seaport) <
            basicOrderParameters.considerationAmount
        ) {
            return false;
        }

        return true;
    }
}

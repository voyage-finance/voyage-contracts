// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VaultFacet} from "../../voyage/facets/VaultFacet.sol";
import {IVault} from "../../vault/Vault.sol";
import {IPaymaster, BasePaymaster, GsnTypes} from "@opengsn/contracts/src/BasePaymaster.sol";
import {IForwarder} from "@opengsn/contracts/src/forwarder/IForwarder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VoyagePaymaster is BasePaymaster {
    error SenderNoVault();
    error VaultBalanceInsufficient();

    address public immutable voyage;
    address public immutable weth9;
    address public treasury;

    uint256 public constant REFUND_GAS_OVERHEAD = 35000;
    uint256 public constant PRE_RELAYED_CALL_OVERHEAD = 60000;
    uint256 public constant POST_RELAYED_CALL_OVERHEAD = 80000;
    uint256 public constant ACCEPTANCE_BUDGET =
        PRE_RELAYED_CALL_OVERHEAD + FORWARDER_HUB_OVERHEAD;
    uint256 public constant CALLDATA_LIMIT = type(uint256).max;

    constructor(
        address _voyage,
        address _weth9,
        address _treasury
    ) {
        if (_voyage == address(0)) {
            revert InvalidVoyageAddress();
        }
        if (_weth9 == address(0)) {
            revert InvalidWeth9Address();
        }
        if (_treasury == address(0)) {
            revert InvalidTreasuryAddress();
        }
        voyage = _voyage;
        weth9 = _weth9;
        treasury = _treasury;
    }

    function versionPaymaster()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "2.2.3+voyage.refundable.ipaymaster";
    }

    /// @inheritdoc IPaymaster
    function getGasAndDataLimits()
        public
        pure
        override
        returns (IPaymaster.GasAndDataLimits memory limits)
    {
        return
            IPaymaster.GasAndDataLimits(
                ACCEPTANCE_BUDGET,
                PRE_RELAYED_CALL_OVERHEAD,
                POST_RELAYED_CALL_OVERHEAD,
                CALLDATA_LIMIT
            );
    }

    /// @inheritdoc IPaymaster
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
        external
        virtual
        override
        returns (bytes memory context, bool revertOnRecipientRevert)
    {
        _verifyForwarder(relayRequest);
        address vault = VaultFacet(voyage).getVaultAddr(
            relayRequest.request.from
        );
        if (vault == address(0)) {
            revert SenderNoVault();
        }
        uint256 ethBalance = vault.balance + IERC20(weth9).balanceOf(vault);
        if (ethBalance < maxPossibleGas * relayRequest.relayData.gasPrice) {
            revert VaultBalanceInsufficient();
        }

        return (abi.encode(vault), true);
    }

    /// @inheritdoc IPaymaster
    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external virtual override relayHubOnly {
        address vault = abi.decode(context, (address));
        // calldata overhead = 21k + non_zero_bytes * 16 + zero_bytes * 4
        //            ~= 21k + calldata.length * [1/3 * 16 + 2/3 * 4]
        uint256 minimumFees = (gasUseWithoutPost +
            21000 +
            msg.data.length *
            8 +
            REFUND_GAS_OVERHEAD) * relayData.gasPrice;
        uint256 refund = vault.balance >= minimumFees
            ? minimumFees
            : minimumFees + 21000 * relayData.gasPrice; // cover cost of unwrapping WETH
        IVault(vault).refundGas(refund, treasury);
    }

    function setTreasuryAddress(address _treasury) public onlyOwner {
        treasury = _treasury;
    }
}

error InvalidVoyageAddress();
error InvalidWeth9Address();
error InvalidTreasuryAddress();

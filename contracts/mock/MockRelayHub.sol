// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import {RelayHub, IStakeManager} from "@opengsn/contracts/src/RelayHub.sol";

contract MockRelayHub is RelayHub {
    constructor(
        IStakeManager _stakeManager,
        address _penalizer,
        uint256 _maxWorkerCount,
        uint256 _gasReserve,
        uint256 _postOverhead,
        uint256 _gasOverhead,
        uint256 _maximumRecipientDeposit,
        uint256 _minimumUnstakeDelay,
        uint256 _minimumStake,
        uint256 _dataGasCostPerByte,
        uint256 _externalCallDataCostOverhead
    )
        RelayHub(
            _stakeManager,
            _penalizer,
            _maxWorkerCount,
            _gasReserve,
            _postOverhead,
            _gasOverhead,
            _maximumRecipientDeposit,
            _minimumUnstakeDelay,
            _minimumStake,
            _dataGasCostPerByte,
            _externalCallDataCostOverhead
        )
    {}
}

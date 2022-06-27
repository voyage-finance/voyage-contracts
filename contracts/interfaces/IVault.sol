// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {MarginEscrow} from "../component/vault/MarginEscrow.sol";

interface IVault {
    struct Call {
        address target;
        bytes callData;
    }

    function initialize(
        address _voyager,
        address _owner,
        address _reserve,
        address _marginEscrow
    ) external;

    function callExternal(Call[] memory calls)
        external
        returns (bytes[] memory);

    function withdrawNFT(
        address _reserve,
        address _target,
        uint256 _tokenId
    ) external;

    function depositMargin(
        address _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable;

    function redeemMargin(
        address payable _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable;

    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) external returns (uint256);

    function transferNFT(
        address _erc721Addr,
        address _to,
        uint256 _num
    ) external;

    function getTotalNFTNumbers(address _erc721Addr)
        external
        view
        returns (uint256);

    function getCurrentMargin(address _reserve) external view returns (uint256);

    function getWithdrawableDeposit(address _sponsor, address _reserve)
        external
        view
        returns (uint256);
}

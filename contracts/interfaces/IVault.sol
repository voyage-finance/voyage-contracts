// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {MarginEscrow} from "../component/vault/MarginEscrow.sol";

interface IVault {
    struct Call {
        address target;
        bytes callData;
    }

    function initialize(address _voyager, address _owner) external;

    function initAsset(address _asset) external returns (address);

    function callExternal(Call[] memory calls)
        external
        returns (bytes[] memory);

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

    function totalDebt(address _reserve) external view returns (uint256);

    function marginRequirement(address _reserve)
        external
        view
        returns (uint256);

    function withdrawableMargin(address _reserve, address _user)
        external
        view
        returns (uint256);

    function totalWithdrawableMargin(address _reserve)
        external
        view
        returns (uint256);
}

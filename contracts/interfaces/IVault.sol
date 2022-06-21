// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SecurityDepositEscrow} from "../component/vault/SecurityDepositEscrow.sol";

interface IVault {
    function initialize(
        address _voyager,
        address _owner,
        address _reserve,
        address _securityDepositEscrow
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

    function getSecurityDepositTokenAddress() external view returns (address);

    function getTotalNFTNumbers(address _erc721Addr)
        external
        view
        returns (uint256);

    function insertNFT(address _erc721Addr, uint256 tokenId) external;

    function underlyingBalance(address _sponsor, address _reserve)
        external
        view
        returns (uint256);

    function getCurrentSecurityDeposit(address _reserve)
        external
        view
        returns (uint256);

    function getWithdrawableDeposit(address _sponsor, address _reserve)
        external
        view
        returns (uint256);
}

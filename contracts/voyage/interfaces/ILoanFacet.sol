// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {PMT} from "../libraries/LibAppStorage.sol";
import {Message} from "../interfaces/IOracleFacet.sol";

struct ExecuteRepayParams {
    address vault;
    uint256 principal;
    uint256 interest;
    uint256 fee;
    uint256 total;
    uint256 totalDebt;
    uint256 incomeRatio;
    uint256 takeRate;
    address treasury;
}

struct PreviewBuyNowParams {
    uint256 epoch;
    uint256 term;
    uint256 nper;
    uint256 totalPrincipal;
    uint256 totalInterest;
    uint256 borrowRate;
    uint256 takeRate;
    uint256 protocolFee;
    uint256 loanId;
    PMT pmt;
}

interface ILoanFacet {
    function previewBuyNowParams(
        address _collection,
        address _vault,
        uint256 _principal
    ) external view returns (PreviewBuyNowParams memory);

    function buyNow(
        address _collection,
        uint256 _tokenId,
        address payable _vault,
        address _marketplace,
        bytes calldata _data
    ) external payable;

    function buyNowV2(
        address _collection,
        uint256 _tokenId,
        address payable _vault,
        address _marketplace,
        bytes calldata _data,
        Message calldata message
    ) external payable;

    function getVaultDebt(address _collection, address _vault)
        external
        view
        returns (uint256, uint256);

    function principalBalance(address _collection)
        external
        view
        returns (uint256);

    function interestBalance(address _collection)
        external
        view
        returns (uint256);

    function seniorInterestBalance(address _collection, address _asset)
        external
        view
        returns (uint256);

    function juniorInterestBalance(address _collection, address _asset)
        external
        view
        returns (uint256);
}

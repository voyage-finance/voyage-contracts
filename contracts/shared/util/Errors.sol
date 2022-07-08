// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error InvalidTotalPaidAndRedeemed(uint256 totalPaid, uint256 totalRedeemed);
error InvalidWithdrawal(uint256 availableAmount, uint256 nftPrice);
error InvalidSenderAddress(address sender);
error InsufficientFund(uint256 reserveBalance);
error InvalidAssetAddress();
error AssetInitialized();
error FailedDeployMarginEscrow();
error FailedDeployCreditEscrow();
error InvalidSubvaultAddress(address subvault);

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibAppStorage, AppStorage, BorrowData} from "./LibAppStorage.sol";

library LibVault {
    function getVaultDebt(address _reserve, address _vault)
        internal
        view
        returns (uint256, uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_reserve][_vault];
        return (borrowData.totalPrincipal, borrowData.totalInterest);
    }
}

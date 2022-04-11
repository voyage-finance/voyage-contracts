// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxy.sol';
import '../../interfaces/IVaultManager.sol';

contract VaultManagerProxy is Proxy {
    /************************** Immutable static call for target contract **************************/

    function getMaxSecurityDeposit(address _reserve)
        public
        view
        returns (uint256)
    {
        return IVaultManager(address(target)).getMaxSecurityDeposit(_reserve);
    }

    function getSecurityDepositRequirement(address _reserve)
        public
        view
        returns (uint256)
    {
        return
            IVaultManager(address(target)).getSecurityDepositRequirement(
                _reserve
            );
    }

    function getCreditLimit(address _user, address _reserve)
        public
        view
        returns (uint256)
    {
        return IVaultManager(address(target)).getCreditLimit(_user, _reserve);
    }

    function getVaultLastUpdateTime(address _vault)
        external
        view
        returns (uint256)
    {
        return IVaultManager(address(target)).getVaultLastUpdateTime(_vault);
    }

    function eligibleAmount(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) external view returns (uint256) {
        return
            IVaultManager(address(target)).eligibleAmount(
                _vaultUser,
                _reserve,
                _sponsor
            );
    }

    function underlyingBalance(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) external view returns (uint256) {
        return
            IVaultManager(address(target)).underlyingBalance(
                _vaultUser,
                _reserve,
                _sponsor
            );
    }
}

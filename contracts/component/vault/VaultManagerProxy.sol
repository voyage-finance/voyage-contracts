// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxy.sol';
import '../../interfaces/IVaultManager.sol';
import '../../interfaces/IVaultManagerProxy.sol';

contract VaultManagerProxy is Proxy, IVaultManagerProxy {
    /************************** Immutable static call for target contract **************************/

    function getVaultConfig(address _reserve)
        external
        view
        returns (DataTypes.VaultConfig memory)
    {
        return IVaultManager(address(target)).getVaultConfig(_reserve);
    }

    function getCreditLimit(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        return IVaultManager(address(target)).getCreditLimit(_user, _reserve);
    }

    function getAvailableCredit(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        return
            IVaultManager(address(target)).getAvailableCredit(_user, _reserve);
    }

    function getSecurityDeposit(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        return
            IVaultManager(address(target)).getSecurityDeposit(_user, _reserve);
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

    function getVault(address _user) external view returns (address) {
        return IVaultManager(address(target)).getVault(_user);
    }

    function getAllVaults() external view returns (address[] memory) {
        return IVaultManager(address(target)).getAllVaults();
    }

    function getGav(address _user) external view returns (uint256) {
        return IVaultManager(address(target)).getGav(_user);
    }
}

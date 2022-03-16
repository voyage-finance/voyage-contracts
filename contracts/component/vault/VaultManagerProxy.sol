// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxy.sol';
import '../../interfaces/IVaultManager.sol';

contract VaultManagerProxy is Proxy {
    /************************** Immutable static call for target contract **************************/

    /**
     * @dev Get max security deposit
     * @param _reserve reserve address
     **/
    function getMaxSecurityDeposit(address _reserve)
        public
        view
        returns (uint256)
    {
        return IVaultManager(address(target)).getMaxSecurityDeposit(_reserve);
    }

    /**
     * @dev Get current security deposit requirement
     * @param _reserve reserve address
     **/
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

    /**
     * @dev Get credit limit for a specific reserve
     * @param _user user address
     * @return _reserve reserve address
     **/
    function getCreditLimit(address _user, address _reserve)
        public
        view
        returns (uint256)
    {
        return IVaultManager(address(target)).getCreditLimit(_user, _reserve);
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
}

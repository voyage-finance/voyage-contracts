// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Vault} from "../component/vault/Vault.sol";
import {SecurityDepositEscrow} from "../component/vault/SecurityDepositEscrow.sol";
import {IVault} from "../interfaces/IVault.sol";
import {LibAppStorage, AppStorage, BorrowData, VaultConfig} from "./LibAppStorage.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";

library LibVault {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    function deployVault(address _owner, bytes32 salt)
        internal
        returns (address, uint256)
    {
        // TODO: Vault should be deployed as a BeaconProxy.
        address vault = Create2.deploy(0, salt, type(Vault).creationCode);
        require(vault != address(0), "deploy vault failed");
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.vaultMap[_owner] == address(0), "one vault per owner");
        s.vaults.push(vault);
        s.vaultMap[_owner] = vault;

        return (vault, s.vaults.length);
    }

    function initVault(address _vault, address _reserve) internal {
        // TODO: SecurityDepositEscrow should be deployed as a BeaconProxy.
        SecurityDepositEscrow securityDepositEscrow = new SecurityDepositEscrow(
            _vault
        );
        IVault(_vault).initialize(address(this), securityDepositEscrow);
        IVault(_vault).initSecurityDepositToken(_reserve);
    }

    /**
     * @dev Set max security deposit for _reserve
     * @param _reserve reserve address
     * @param _amount max amount sponsor can deposit
     */
    function setMaxSecurityDeposit(address _reserve, uint256 _amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vaultConfigMap[_reserve].maxSecurityDeposit = _amount;
    }

    function setMinSecurityDeposit(address _reserve, uint256 _amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vaultConfigMap[_reserve].minSecurityDeposit = _amount;
    }

    function setSecurityDepositRequirement(
        address _reserve,
        uint256 _requirement
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vaultConfigMap[_reserve].securityDepositRequirement = _requirement;
    }

    /* ----------------------------- view functions ----------------------------- */
    function getVaultAddress(address _owner) internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.vaultMap[_owner];
    }

    function getVaultDebt(address _reserve, address _vault)
        internal
        view
        returns (uint256, uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_reserve][_vault];
        return (borrowData.totalPrincipal, borrowData.totalInterest);
    }

    function getVaultConfig(address _reserve)
        internal
        view
        returns (VaultConfig memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.vaultConfigMap[_reserve];
    }

    /**
     * @dev Get available credit
     * @param _user user address
     * @param _reserve reserve address
     **/
    function getAvailableCredit(address _user, address _reserve)
        internal
        view
        returns (uint256)
    {
        uint256 creditLimit = getCreditLimit(_user, _reserve);
        uint256 principal;
        uint256 interest;
        address vault = getVaultAddress(_user);
        getVaultDebt(_reserve, vault);
        uint256 accumulatedDebt = principal.add(interest);
        if (creditLimit < accumulatedDebt) {
            return 0;
        }
        return creditLimit - accumulatedDebt;
    }

    /**
     * @dev Get credit limit for a specific reserve
     * @param _user user address
     * @return _reserve reserve address
     **/
    function getCreditLimit(address _user, address _reserve)
        internal
        view
        returns (uint256)
    {
        uint256 currentSecurityDeposit = getSecurityDeposit(_user, _reserve);
        VaultConfig memory vc = getVaultConfig(_reserve);
        uint256 securityDepositRequirement = vc.securityDepositRequirement;
        require(
            securityDepositRequirement != 0,
            "security deposit requirement cannot be 0"
        );
        uint256 creditLimitInRay = currentSecurityDeposit.wadToRay().rayDiv(
            securityDepositRequirement
        );
        return creditLimitInRay.rayToWad();
    }

    function getSecurityDeposit(address _user, address _reserve)
        internal
        view
        returns (uint256)
    {
        address vault = getVaultAddress(_user);
        return IVault(vault).getCurrentSecurityDeposit(_reserve);
    }

    function getSecurityDepositTokenAddress(address vault)
        internal
        view
        returns (address)
    {
        return IVault(vault).getSecurityDepositTokenAddress();
    }

    function getWithdrawableDeposit(
        address _owner,
        address _reserve,
        address _sponsor
    ) internal view returns (uint256) {
        address vault = getVaultAddress(_owner);
        return IVault(vault).getWithdrawableDeposit(_sponsor, _reserve);
    }
}

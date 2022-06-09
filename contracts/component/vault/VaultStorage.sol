// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../../libraries/state/State.sol";
import "../../libraries/types/DataTypes.sol";
import "../../libraries/math/WadRayMath.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

// central storage for all vaults
contract VaultStorage is State {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    address[] public allVaults;
    // player address => vault address
    mapping(address => address) public getVault;

    mapping(address => DataTypes.VaultConfig) public vaultConfig;

    constructor(address _vaultManager) State(_vaultManager) {}

    function pushNewVault(address _player, address vault)
        external
        onlyAssociatedContract
        returns (uint256)
    {
        allVaults.push(vault);
        require(getVault[_player] == address(0), "vault exists");
        getVault[_player] = vault;
        return allVaults.length;
    }

    function setMaxSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyAssociatedContract
    {
        vaultConfig[_reserve].maxSecurityDeposit = _amount;
    }

    function setMinSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyAssociatedContract
    {
        vaultConfig[_reserve].minSecurityDeposit = _amount;
    }

    function setSecurityDepositRequirement(
        address _reserve,
        uint256 _requirement
    ) external onlyAssociatedContract {
        vaultConfig[_reserve].securityDepositRequirement = _requirement;
    }

    /**
     * @dev Get Vault address for a specific user
     * @param _user the address of the player
     **/
    function getVaultAddress(address _user) external view returns (address) {
        return getVault[_user];
    }

    /**
     * @dev Get all credit account addresses
     **/
    function getAllVaults() external view returns (address[] memory) {
        return allVaults;
    }

    function getVaultConfig(address _reserve)
        external
        view
        returns (DataTypes.VaultConfig memory)
    {
        return vaultConfig[_reserve];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/state/State.sol';
import '../../libraries/types/DataTypes.sol';
import '../../libraries/math/WadRayMath.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';

// central storage for all vaults
contract VaultStorage is State {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    address[] public allVaults;
    // player address => vault address
    mapping(address => address) public getVault;

    mapping(address => DataTypes.VaultData) public vaultData;

    constructor(address _vaultManager) State(_vaultManager) {}

    function pushNewVault(address _player, address vault)
        external
        onlyAssociatedContract
        returns (uint256)
    {
        allVaults.push(vault);
        getVault[_player] = vault;
        return allVaults.length;
    }

    function addNewDebt(
        address _vault,
        uint256 _amount,
        uint256 _tenure,
        uint256 _timestamp
    ) external onlyAssociatedContract {
        DataTypes.VaultData storage vd = vaultData[_vault];
        //DataTypes.DrawDown memory drawDone;
        //        drawDone.amount = _amount;
        //        drawDone.tenure = _tenure;
        //        drawDone.timestamp = _timestamp;
        //vd.drawDowns[vd.drawDownNumber] = drawDone;
        //        vd.drawDownNumber += 1;
    }

    //    function getDrawDownData(address _vault)
    //        external
    //        view
    //        returns ( mapping(uint256 => DataTypes.DrawDown) memory)
    //    {
    //        DataTypes.VaultData memory vd = vaultData[_vault];
    //        return vd.drawDowns;
    //    }

    function getVaultLastUpdateTime(address _vault)
        external
        view
        returns (uint256)
    {
        DataTypes.VaultData storage vd = vaultData[_vault];
        return vd.lastUpdateTime;
    }

    function getAggregateOptimalRepaymentRate(address _vault)
        external
        view
        returns (uint256)
    {
        DataTypes.VaultData storage vd = vaultData[_vault];
        uint256 aggregateOptimalRepaymentRate;
        //        for (uint256 i = 0; i < vd.drawDownNumber; i++) {
        //            aggregateOptimalRepaymentRate += vd.drawDowns[i].amount.rayDiv(
        //                vd.drawDowns[i].tenure
        //            );
        //        }
        return aggregateOptimalRepaymentRate;
    }

    function getAggregateActualRepaymentRate(address _vault)
        external
        view
        returns (uint256)
    {
        DataTypes.VaultData storage vd = vaultData[_vault];
        uint256 aggregateActualRepayment;
        //        for (uint256 i = 0; i < vd.drawDownNumber; i++) {
        //            aggregateActualRepayment += vd.repayments[i].totalPaid.rayDiv(
        //                vd.repayments[i].tenurePassed
        //            );
        //        }
        return aggregateActualRepayment;
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
}

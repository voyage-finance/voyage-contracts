// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../interfaces/IHealthStrategy.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../libraries/types/DataTypes.sol';

contract DefaultHealthStrategy is IHealthStrategy{
    using WadRayMath for uint256;
    using SafeMath for uint256;

    // A number >= 1 by which loan amount is multiplied. Riskier assets will attract
    // a higher PF, effectively increasing the expected repayment rate. Expressed in ray
    uint256 internal immutable premiumFactor;

    uint256 internal immutable loanTenure;

    constructor(uint256 _premiumFactor, uint256 _loanTenure) public {
        premiumFactor = _premiumFactor;
        loanTenure = _loanTenure;
    }

    function getPrincipalDebt(DataTypes.DrawDown memory _drawDown)
        external
        view
        returns (uint256)
    {
        return premiumFactor.add(WadRayMath.Ray()).rayMul(_drawDown.amount);
    }

    function calculateHealthRisk(
        uint256 _securityDeposit,
        DataTypes.DrawDown memory _drawDown
    ) external view returns (uint256) {
        //todo
        return 1;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../interfaces/IHealthStrategy.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../libraries/math/MathUtils.sol';
import '../../libraries/types/DataTypes.sol';

contract DefaultHealthStrategy is IHealthStrategy {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    // A number >= 1 by which loan amount is multiplied. Riskier assets will attract
    // a higher PF, effectively increasing the expected repayment rate. Expressed in ray
    uint256 internal immutable premiumFactor;

    uint256 internal immutable loanTenure;

    uint256 internal immutable wightedLTV;

    uint256 internal immutable weightedRepaymentRatio;

    constructor(
        uint256 _premiumFactor,
        uint256 _loanTenure,
        uint256 _wightedLTV,
        uint256 _weightedRepaymentRatio
    ) public {
        premiumFactor = _premiumFactor;
        loanTenure = _loanTenure;
        wightedLTV = _wightedLTV;
        weightedRepaymentRatio = _weightedRepaymentRatio;
    }

    function getPrincipalDebt(DataTypes.DrawDown memory _drawDown)
        internal
        view
        returns (uint256)
    {
        return premiumFactor.add(WadRayMath.Ray()).rayMul(_drawDown.amount);
    }

    function calculateHealthRisk(
        uint256 _securityDeposit,
        uint256 _currentBorrowRate,
        uint40 _lastTimestamp,
        DataTypes.DrawDown memory _drawDown,
        uint256 _grossAssetValue
    ) external view returns (uint256) {
        //todo
        // 1. calculate principal debt
        // 2. calculate compounded debt
        // 3. calculate LTV ratio
        uint256 principalDebt = getPrincipalDebt(_drawDown);
        uint256 compoundedDebt = MathUtils
            .calculateCompoundedInterest(_currentBorrowRate, _lastTimestamp)
            .rayMul(principalDebt);
        uint256 ltvRatio = _grossAssetValue.add(_securityDeposit).rayDiv(
            compoundedDebt
        );
        return 1;
    }
}

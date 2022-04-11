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

    // Tenure for a given draw down
    uint256 internal immutable loanTenure;

    // Wight of LTV in HF computation
    uint256 internal immutable wightedLTV;

    // Wight of RR(Repayment Ratio) in HF computation
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

    function getPrincipalDebt(uint256 _amount) internal view returns (uint256) {
        return premiumFactor.add(WadRayMath.Ray()).rayMul(_amount);
    }

    function calculateHealthRisk(
        uint256 _securityDeposit,
        uint256 _currentBorrowRate,
        uint40 _lastTimestamp,
        uint256 _amount,
        uint256 _grossAssetValue,
        uint256 _aggregateOptimalRepaymentRate,
        uint256 _aggregateActualRepaymentRate
    ) external view returns (uint256) {
        // 1. calculate principal debt
        // 2. calculate compounded debt
        // 3. calculate LTV ratio
        // 4. calculate repayment ratio
        uint256 principalDebt = getPrincipalDebt(_amount);
        uint256 compoundedDebt = MathUtils
            .calculateCompoundedInterest(_currentBorrowRate, _lastTimestamp)
            .rayMul(principalDebt);
        uint256 ltvRatio = _grossAssetValue.add(_securityDeposit).rayDiv(
            compoundedDebt
        );
        uint256 repaymentRatio = _aggregateActualRepaymentRate.rayDiv(
            _aggregateOptimalRepaymentRate
        );
        return
            ltvRatio
                .rayMul(wightedLTV)
                .add(repaymentRatio.rayMul(weightedRepaymentRatio))
                .rayDiv(wightedLTV.add(weightedRepaymentRatio));
    }
}

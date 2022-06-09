// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IHealthStrategy} from "../../interfaces/IHealthStrategy.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";

contract DefaultHealthStrategy is IHealthStrategy {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    uint256 internal constant RAY = 1e27;

    // A number >= 1 by which loan amount is multiplied. Riskier assets will attract
    // a higher PF, effectively increasing the expected repayment rate. Expressed in ray
    uint256 internal immutable premiumFactor;

    // Tenure for a given draw down
    uint256 internal immutable loanTenure;

    // Weight of LTV in HF computation
    uint256 internal immutable weightedLTV;

    // Wight of RR(Repayment Ratio) in HF computation
    uint256 internal immutable weightedRepaymentRatio;

    constructor(
        uint256 _premiumFactor,
        uint256 _loanTenure,
        uint256 _weightedLTV,
        uint256 _weightedRepaymentRatio
    ) public {
        premiumFactor = _premiumFactor;
        loanTenure = _loanTenure;
        weightedLTV = _weightedLTV;
        weightedRepaymentRatio = _weightedRepaymentRatio;
    }

    function getPrincipalDebt(uint256 _amount) internal view returns (uint256) {
        return premiumFactor.add(WadRayMath.Ray()).rayMul(_amount);
    }

    function calculateHealthRisk(DataTypes.HealthRiskParameter memory hrp)
        external
        view
        returns (uint256)
    {
        if (hrp.compoundedDebt == 0) {
            return RAY;
        }
        uint256 ltvRatio = hrp.grossAssetValue.add(hrp.securityDeposit).rayDiv(
            hrp.compoundedDebt
        );
        // todo
        uint256 repaymentRatio = 1;
        return
            ltvRatio
                .rayMul(weightedLTV)
                .add(repaymentRatio.rayMul(weightedRepaymentRatio))
                .rayDiv(weightedLTV.add(weightedRepaymentRatio));
    }

    function getPremiumFactor() external view returns (uint256) {
        return premiumFactor;
    }

    function getLoanTenure() external view returns (uint256) {
        return loanTenure;
    }

    function getWeightedLTV() external view returns (uint256) {
        return weightedLTV;
    }

    function getWeightedRepaymentRatio() external view returns (uint256) {
        return weightedRepaymentRatio;
    }
}

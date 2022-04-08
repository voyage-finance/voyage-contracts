// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../interfaces/IHealthStrategy.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import '../../libraries/math/WadRayMath.sol';

contract DefaultHealthStrategy is IHealthStrategy {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    // A number >= 1 by which loan amount is multiplied. Riskier assets will attract
    // a higher PF, effectively increasing the expected repayment rate. Expressed in ray
    uint256 internal immutable premiumFactor;

    uint256 internal immutable loanPeriod;

    constructor(uint256 _premiumFactor, uint256 _loanPeriod) public {
        premiumFactor = _premiumFactor;
        loanPeriod = _loanPeriod;
    }

    function calculateHealthRisk() external view returns (uint256) {
        //todo
        //return 1;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import 'hardhat/console.sol';

library LibFinancial {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    uint256 internal constant RAY = 1e27;

    /**
     * @dev Function to compute the payment against loan principal plus interest
     * The payment is computed by solving the equation:
     *  fv + pv*(1 + rate)**nper + pmt*(1 + rate*when(0))/rate*((1 + rate)**nper - 1) == 0
     * @param rate The interest rate per period, in Ray
     * @param nper Number of compounding periods
     * @param pv Present value (amount borrowed)
     * @return The fixed periodic payment, in wad
     **/
    function pmt(
        uint256 rate,
        uint256 nper,
        uint256 pv
    ) public view returns (uint256, bool) {
        uint256 temp = rate.add(RAY).rayPow(nper);
        uint256 masked_rate = rate;
        uint256 fact = nper;
        if (rate == 0) {
            masked_rate = RAY;
        } else {
            fact = temp.sub(RAY).rayDiv(masked_rate);
        }

        uint256 pvRay = pv.wadToRay();
        return (pvRay.rayMul(temp).rayDiv(fact).rayToWad(), false);
    }

    /**
     * @dev Function to compute the future value
     * @param rate The interest rate
     * @param nper Number of compounding periods
     * @param pmt Payment
     * @param pv Present value
     * @return The future value, in wad
     **/
    function fv(
        uint256 rate,
        uint256 nper,
        uint256 pmt,
        bool pmtsign,
        uint256 pv,
        bool pvsign
    ) public view returns (uint256) {
        uint256 temp = rate.add(RAY).rayPow(nper);
        uint256 pvRay = pv.wadToRay();
        uint256 pmtRay = pmt.wadToRay();
        uint256 parta = temp.rayMul(pvRay);
        uint256 partb = pmtRay.rayDiv(rate).rayMul(temp.sub(RAY));
        uint256 fv = 0;
        if (pvsign && !pmtsign) {
            fv = parta.sub(partb);
        } else {
            fv = partb.sub(parta);
        }
        return fv.rayToWad();
    }

    /**
     * @dev Function to compute the interest portion of a payment
     * @param rate The interest rate
     * @param per The payment period to calculate the interest amount
     * @param nper Number of compounding periods
     * @param pv Present value
     * @return The interest portion of payment, in wad
     **/
    function ipmt(
        uint256 rate,
        uint256 per,
        uint256 nper,
        uint256 pv
    ) public view returns (uint256) {
        (uint256 totalPmt, bool pmtsign) = pmt(rate, nper, pv);
        uint256 fvRay = fv(rate, per - 1, totalPmt, pmtsign, pv, true)
            .wadToRay();
        return fvRay.rayMul(rate).rayDiv(rate.add(RAY)).rayToWad();
    }

    /**
     * @dev Function to compute the payment against load principal
     * @param rate The interest rate
     * @param per The payment period to calculate the interest amount
     * @param nper Number of compounding periods
     * @param pv Present value
     * @return The payment, in wad
     **/
    function ppmt(
        uint256 rate,
        uint256 per,
        uint256 nper,
        uint256 pv
    ) public view returns (uint256) {
        (uint256 totalPmt, bool sign) = pmt(rate, nper, pv);
        return totalPmt.sub(ipmt(rate, per, nper, pv));
    }
}

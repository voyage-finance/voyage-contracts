// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20, ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {EthAddressLib} from "../../libraries/EthAddressLib.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";

contract MarginEscrow is ERC4626, ReentrancyGuard {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using Address for address payable;
    using SafeTransferLib for ERC20;

    event Deposited(address indexed payee, address token, uint256 amount);
    event Withdrawn(address indexed payee, address token, uint256 amount);

    address public voyager;
    address public vault;

    // reserve address => amount
    modifier onlyOwner() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    constructor(
        address _vault,
        address _voyager,
        address _asset
    ) ERC4626(ERC20(_asset), ERC20(_asset).name(), ERC20(_asset).symbol()) {
        voyager = _voyager;
        vault = _vault;
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function slash(uint256 _amount, address payable _to)
        public
        payable
        nonReentrant
        onlyOwner
        returns (uint256)
    {
        uint256 balance = totalAssets();
        if (balance < _amount) {
            _amount = balance;
        }
        transferUnderlyingTo(_to, _amount);
        return _amount;
    }

    function withdraw(
        uint256 _amount,
        address _receiver,
        address _user
    ) public override onlyOwner returns (uint256) {
        uint256 withdrawableBalance = withdrawableMargin(_user);
        require(
            withdrawableBalance >= _amount,
            "Amount exceeds withdrawable balance"
        );
        return super.withdraw(_amount, _receiver, _user);
    }

    function withdrawableMargin(address _user) public view returns (uint256) {
        uint256 totalWithdrawable = totalWithdrawableMargin();
        uint256 userBalance = maxWithdraw(_user);
        if (totalWithdrawable >= userBalance) {
            return userBalance;
        }
        return totalWithdrawable;
    }

    function totalWithdrawableMargin() public view returns (uint256) {
        IVault v = IVault(vault);
        address _asset = address(asset);
        uint256 vaultDebt = v.totalDebt(_asset);
        uint256 marginRequirement = v.marginRequirement(_asset);
        uint256 totalMargin = totalMargin();
        uint256 marginMin = vaultDebt
            .wadToRay()
            .rayMul(marginRequirement)
            .rayToWad();
        if (totalMargin >= marginMin) {
            return totalMargin.sub(marginMin);
        }
        return 0;
    }

    /**
     * @dev get accumulated amount of deposit.
     * @return accumulated deposit amount
     **/
    function totalMargin() public view returns (uint256) {
        return totalAssets();
    }

    function transferUnderlyingTo(address _target, uint256 _amount)
        public
        onlyOwner
    {
        asset.safeTransfer(_target, _amount);
    }
}

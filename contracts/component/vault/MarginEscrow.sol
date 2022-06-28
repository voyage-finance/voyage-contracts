// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IMarginEscrow} from "../../interfaces/IMarginEscrow.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {EthAddressLib} from "../../libraries/EthAddressLib.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC4626, IERC4626} from "../../tokenization/base/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MarginEscrow is
    Initializable,
    ERC4626,
    IMarginEscrow,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20Metadata;
    using Address for address payable;

    event Deposited(address indexed payee, address token, uint256 amount);
    event Withdrawn(address indexed payee, address token, uint256 amount);

    address public voyager;
    address public vault;

    // reserve address => amount
    modifier onlyOwner() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    function initialize(
        address _vault,
        address _voyager,
        address _asset
    ) public initializer {
        voyager = _voyager;
        vault = _vault;
        IERC20Metadata underlying = IERC20Metadata(_asset);
        __ERC20_init(underlying.name(), underlying.symbol());
        __ERC20Permit_init(underlying.name());
        __ERC4626_init(underlying);
    }

    function totalAssets()
        public
        view
        override(ERC4626, IERC4626)
        returns (uint256)
    {
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
    ) public override(ERC4626, IERC4626) onlyOwner returns (uint256) {
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

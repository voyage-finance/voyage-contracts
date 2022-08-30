// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC4626, IERC4626} from "../../shared/tokenization/ERC4626.sol";
import {IVToken} from "../interfaces/IVToken.sol";

abstract contract VToken is Initializable, ERC4626, IVToken {
    using SafeERC20 for IERC20Metadata;

    address internal voyage;
    address internal collection;

    modifier onlyAdmin() {
        require(_msgSender() == voyage, "Not admin");
        _;
    }

    /* --------------------------------- public functions -------------------------------- */

    function initialize(
        address _voyage,
        address _collection,
        address _asset
    ) public initializer {
        IERC20Metadata underlying = IERC20Metadata(_asset);
        voyage = _voyage;
        collection = _collection;
        __ERC20_init(underlying.name(), underlying.symbol());
        __ERC20Permit_init(underlying.name());
        __ERC4626_init(underlying);
    }

    function transferUnderlyingTo(address _target, uint256 _amount)
        public
        onlyAdmin
    {
        asset.safeTransfer(_target, _amount);
    }
}

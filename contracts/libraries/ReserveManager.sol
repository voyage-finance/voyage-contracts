// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import './ownership/Ownable.sol';
import './CoreLibrary.sol';
import '../tokenization/JuniorDepositToken.sol';
import '../tokenization/SeniorDepositToken.sol';
import '../interfaces/IReserveInterestRateStrategy.sol';
import './EthAddressLib.sol';
import '../interfaces/IReserveManager.sol';

contract ReserveManager is Ownable, ReentrancyGuard, IReserveManager {
    using CoreLibrary for CoreLibrary.ReserveData;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    mapping(address => CoreLibrary.ReserveData) _reserves;

    address lendingPoolManager;

    modifier onlyLendingPoolManager() {
        require(
            lendingPoolManager == msg.sender,
            'The caller must be a lending pool manager'
        );
        _;
    }

    /**
     * @dev functions affected by this modifier can only be invoked if the reserve is active
     * @param _reserve the address of the reserve
     **/
    modifier onlyActiveReserve(address _reserve) {
        requireReserveActiveInternal(_reserve);
        _;
    }

    /**
     * @dev functions affected by this modifier can only be invoked if the provided _amount input parameter
     * is not zero.
     * @param _amount the amount provided
     **/
    modifier onlyAmountGreaterThanZero(uint256 _amount) {
        requireAmountGreaterThanZeroInternal(_amount);
        _;
    }

    /**
     * @dev internal function to save on code size for the onlyActiveReserve modifier
     **/
    function requireReserveActiveInternal(address _reserve) internal view {
        require(
            getReserveIsActive(_reserve),
            'Action requires an active reserve'
        );
    }

    /**
     * @notice internal function to save on code size for the onlyAmountGreaterThanZero modifier
     **/
    function requireAmountGreaterThanZeroInternal(uint256 _amount)
        internal
        pure
    {
        require(_amount > 0, 'Amount must be greater than 0');
    }

    /**
     * @dev returns true if the reserve is active
     * @param _reserve the reserve address
     * @return true if the reserve is active, false otherwise
     **/
    function getReserveIsActive(address _reserve) internal view returns (bool) {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        // todo
        return true;
    }

    /**
     * @dev gets the available liquidity in the reserve. The available liquidity is the balance of the core contract
     * @param _reserve the reserve address
     * @return the available liquidity
     **/
    function getReserveAvailableLiquidity(address _reserve)
        public
        view
        returns (uint256)
    {
        uint256 balance = 0;

        if (_reserve == EthAddressLib.ethAddress()) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_reserve).balanceOf(address(this));
        }
        return balance;
    }

    /**
     * @dev gets the total liquidity in the reserve. The total liquidity is the balance of the core contract + total borrows
     * @param _reserve the reserve address
     * @return the total liquidity
     **/
    function getReserveTotalLiquidity(address _reserve)
        public
        view
        returns (uint256)
    {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        return getReserveAvailableLiquidity(_reserve).add(reserve.totalBorrows);
    }

    /**
     * @dev Init a reserve with necessary data
     * @param _reserve the reserve address
     * @param _jdTokenName the name of junior deposit token
     * @param _jdTokenSymbol the symbol of junior deposit token
     * @param _sdTokenName the name of senior deposit token
     * @param _sdTokenSymbol  the symbol of senior deposit token
     * @param _underlyingAssetDecimals the decimal of underlying asset
     * @param _interestRateStrategyAddress interest rate strategy contract address
     * @param _securityRequirement security requirement express in Ray
     **/
    function initReserveWithData(
        address _reserve,
        string memory _jdTokenName,
        string memory _jdTokenSymbol,
        string memory _sdTokenName,
        string memory _sdTokenSymbol,
        uint8 _underlyingAssetDecimals,
        address _interestRateStrategyAddress,
        uint256 _securityRequirement
    ) public onlyLendingPoolManager {
        JuniorDepositToken jdTokenInstance = new JuniorDepositToken(
            _reserve,
            _underlyingAssetDecimals,
            _jdTokenName,
            _jdTokenSymbol
        );

        SeniorDepositToken sdTokenInstance = new SeniorDepositToken(
            _reserve,
            _underlyingAssetDecimals,
            _sdTokenName,
            _sdTokenSymbol
        );

        _reserves[_reserve].init(
            address(jdTokenInstance),
            address(sdTokenInstance),
            _underlyingAssetDecimals,
            _interestRateStrategyAddress,
            _securityRequirement
        );

        emit ReserveInitialized(
            _reserve,
            address(jdTokenInstance),
            address(sdTokenInstance),
            _interestRateStrategyAddress
        );
    }

    function initReserve(
        address _reserve,
        uint8 _underlyingAssetDecimals,
        address _interestRateStrategyAddress,
        uint256 _securityRequirement
    ) external onlyLendingPoolManager {
        ERC20 asset = ERC20(_reserve);
        string memory _jdTokenName = string(
            abi.encodePacked(
                'Voyage Junior Deposit Interest bearing ',
                asset.name()
            )
        );
        string memory _jdTokenSymbol = string(
            abi.encodePacked('vj', asset.symbol())
        );
        string memory _sdTokenName = string(
            abi.encodePacked(
                'Voyage Senior Deposit Interest bearing ',
                asset.name()
            )
        );
        string memory _sdTokenSymbol = string(
            abi.encodePacked('vs', asset.symbol())
        );

        initReserveWithData(
            _reserve,
            _jdTokenName,
            _jdTokenSymbol,
            _sdTokenName,
            _sdTokenSymbol,
            _underlyingAssetDecimals,
            _interestRateStrategyAddress,
            _securityRequirement
        );
    }

    /**
     * @dev activates a reserve
     * @param _reserve the address of the reserve
     **/
    function activateReserve(address _reserve) external onlyLendingPoolManager {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        require(
            reserve.currentJuniorLiquidityIndex > 0,
            'Reserve has not been initialized yet'
        );
        // todo
        //reserve.isActive = true;
        emit ReserveActivated(_reserve);
    }

    /**
     * @dev deactivates a reserve
     * @param _reserve the address of the reserve
     **/
    function deactivateReserve(address _reserve)
        external
        onlyLendingPoolManager
    {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        require(
            getReserveTotalLiquidity(_reserve) == 0,
            'The liquidity of the reserve needs to be 0'
        );
        // todo
        //reserve.isActive = false;
        emit ReserveDeactivated(_reserve);
    }

    /**
     * @dev transfers to the user a specific amount from the reserve.
     * @param _reserve the address of the reserve where the transfer is happening
     * @param _user the address of the user receiving the transfer
     * @param _amount the amount being transferred
     **/
    function transferToUser(
        address _reserve,
        address payable _user,
        uint256 _amount
    ) internal {
        if (_reserve != EthAddressLib.ethAddress()) {
            ERC20(_reserve).safeTransfer(_user, _amount);
        } else {
            //solium-disable-next-line
            (bool result, ) = _user.call{value: _amount}('');
            require(result, 'Transfer of ETH failed');
        }
    }
}

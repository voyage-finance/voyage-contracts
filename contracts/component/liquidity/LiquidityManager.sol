// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/ownership/Ownable.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../libraries/CoreLibrary.sol';
import '../../libraries/EthAddressLib.sol';
import '../../credit/CreditAccount.sol';
import '../../interfaces/IReserveInterestRateStrategy.sol';
import '../../interfaces/ICreditAccount.sol';
import '../../tokenization/JDToken.sol';
import '../../tokenization/SDToken.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';

contract LiquidityManager is Ownable, ReentrancyGuard {
    using CoreLibrary for CoreLibrary.ReserveData;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /**
     * @dev emitted when a reserve is initialized.
     * @param _reserve the address of the reserve
     * @param _jdToken the address of the overlying jdToken contract
     * @param _jdToken the address of the overlying sdToken contract
     * @param _interestRateStrategyAddress the address of the interest rate strategy for the reserve
     **/
    event ReserveInitialized(
        address indexed _reserve,
        address indexed _jdToken,
        address indexed _sdToken,
        address _interestRateStrategyAddress
    );

    /**
     * @dev emitted when a reserve is activated
     * @param _reserve the address of the reserve
     **/
    event ReserveActivated(address indexed _reserve);

    /**
     * @dev emitted when a reserve is deactivated
     * @param _reserve the address of the reserve
     **/
    event ReserveDeactivated(address indexed _reserve);

    /**
     * @dev Emitted when the state of a reserve is updated
     * @param reserve the address of the reserve
     * @param liquidityRate the new liquidity rate
     * @param currentJuniorLiquidityIndex the new junior liquidity index
     * @param currentSeniorLiquidityIndex the new senior liquidity index
     **/
    event ReserveUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 currentJuniorLiquidityIndex,
        uint256 currentSeniorLiquidityIndex
    );

    /**
     * @dev emitted on deposit
     * @param _reserve the address of the reserve
     * @param _user the address of the user
     * @param _amount the amount to be deposited
     * @param _timestamp the timestamp of the action
     **/
    event Deposit(
        address indexed _reserve,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );

    /**
     * @dev emitted during a redeem action.
     * @param _reserve the address of the reserve
     * @param _user the address of the user
     * @param _amount the amount to be deposited
     * @param _timestamp the timestamp of the action
     **/
    event RedeemUnderlying(
        address indexed _reserve,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );

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
     * @dev functions affected by this modifier can only be invoked by the
     * aToken.sol contract
     * @param _reserve the address of the reserve
     **/
    modifier onlyOverlyingToken(address _reserve) {
        require(
            msg.sender == getReserveJDTokenAddress(_reserve) ||
                msg.sender == getReserveSDTokenAddress(_reserve),
            'The caller of this function can only be the jsToken or sdToken contract of this reserve'
        );
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
     * @dev gets the jdToken contract address for the reserve
     * @param _reserve the reserve address
     * @return the address of the jdToken contract
     **/
    function getReserveJDTokenAddress(address _reserve)
        public
        view
        returns (address)
    {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        return reserve.jdTokenAddress;
    }

    /**
     * @dev gets the sdToken contract address for the reserve
     * @param _reserve the reserve address
     * @return the address of the sdToken contract
     **/
    function getReserveSDTokenAddress(address _reserve)
        public
        view
        returns (address)
    {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        return reserve.sdTokenAddress;
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

    function initReserveWithData(
        address _reserve,
        string memory _jdTokenName,
        string memory _jdTokenSymbol,
        string memory _sdTokenName,
        string memory _sdTokenSymbol,
        uint8 _underlyingAssetDecimals,
        address _interestRateStrategyAddress
    ) public onlyLendingPoolManager {
        JDToken jdTokenInstance = new JDToken(
            _reserve,
            _underlyingAssetDecimals,
            _jdTokenName,
            _jdTokenSymbol
        );

        SDToken sdTokenInstance = new SDToken(
            _reserve,
            _underlyingAssetDecimals,
            _sdTokenName,
            _sdTokenSymbol
        );

        _reserves[_reserve].init(
            address(jdTokenInstance),
            address(sdTokenInstance),
            _underlyingAssetDecimals,
            _interestRateStrategyAddress
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
        address _interestRateStrategyAddress
    ) external onlyLendingPoolManager {
        ERC20 asset = ERC20(_reserve);
        string memory _jdTokenName = string(
            abi.encodePacked(
                'Voyage Junor Deposit Interest bearing ',
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
            _interestRateStrategyAddress
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
     * @dev gets the normalized income of the reserve. a value of 1e27 means there is no income. A value of 2e27 means there
     * there has been 100% income.
     * @param _reserve the reserve address
     * @param _tranche the tranche of the reserve
     * @return the reserve normalized income
     **/
    function getReserveNormalizedIncome(
        address _reserve,
        CoreLibrary.Tranche _tranche
    ) external view returns (uint256) {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        return reserve.getNormalizedIncome(_tranche);
    }

    /**
     * @dev updates the state of the core as a result of a deposit action
     * @param _reserve the address of the reserve in which the deposit is happening
     * @param _user the address of the the user depositing
     * @param _amount the amount being deposited
     **/

    function updateStateOnDeposit(
        address _reserve,
        CoreLibrary.Tranche _tranche,
        address _user,
        uint256 _amount
    ) internal {
        _reserves[_reserve].updateCumulativeIndexes(_tranche);
        updateReserveInterestRatesAndTimestampInternal(_reserve, _amount, 0);
    }

    /**
     * @dev updates the state of the core as a result of a redeem action
     * @param _reserve the address of the reserve in which the redeem is happening
     * @param _tranche the tranche of the reserve
     * @param _user the address of the the user redeeming
     * @param _amountRedeemed the amount being redeemed
     * @param _userRedeemedEverything true if the user is redeeming everything
     **/
    function updateStateOnRedeem(
        address _reserve,
        CoreLibrary.Tranche _tranche,
        address _user,
        uint256 _amountRedeemed,
        bool _userRedeemedEverything
    ) internal {
        //compound liquidity and variable borrow interests
        _reserves[_reserve].updateCumulativeIndexes(_tranche);
        updateReserveInterestRatesAndTimestampInternal(
            _reserve,
            0,
            _amountRedeemed
        );
    }

    /**
     * @dev Updates the reserve current stable borrow rate Rf, the current variable borrow rate Rv and the current liquidity rate Rl.
     * Also updates the lastUpdateTimestamp value. Please refer to the whitepaper for further information.
     * @param _reserve the address of the reserve to be updated
     * @param _liquidityAdded the amount of liquidity added to the protocol (deposit or repay) in the previous action
     * @param _liquidityTaken the amount of liquidity taken from the protocol (redeem or borrow)
     **/

    function updateReserveInterestRatesAndTimestampInternal(
        address _reserve,
        uint256 _liquidityAdded,
        uint256 _liquidityTaken
    ) internal {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        // todo
        uint256 newLiquidityRate = IReserveInterestRateStrategy(
            reserve.interestRateStrategyAddress
        ).calculateInterestRates(
                _reserve,
                getReserveAvailableLiquidity(_reserve).add(_liquidityAdded).sub(
                    _liquidityTaken
                ),
                reserve.totalBorrows
            );

        reserve.currentOverallLiquidityRate = newLiquidityRate;

        //solium-disable-next-line
        reserve.lastUpdateTimestamp = uint40(block.timestamp);

        emit ReserveUpdated(
            _reserve,
            newLiquidityRate,
            reserve.currentJuniorLiquidityIndex,
            reserve.currentSeniorLiquidityIndex
        );
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

    /**
     * @dev depositLiquidity The underlying asset into the reserve. A corresponding amount of the overlying asset
     * is minted.
     * @param _reserve the address of the reserve
     * @param _tranche the tranche of thereserve
     * @param _amount the amount to be deposited
     **/
    function depositLiquidity(
        address _reserve,
        CoreLibrary.Tranche _tranche,
        uint256 _amount
    )
        external
        payable
        nonReentrant
        onlyActiveReserve(_reserve)
        onlyAmountGreaterThanZero(_amount)
    {
        updateStateOnDeposit(_reserve, _tranche, msg.sender, _amount);

        if (_tranche == CoreLibrary.Tranche.JUNIOR) {
            JDToken jdToken = JDToken(getReserveJDTokenAddress(_reserve));
            jdToken.mintOnDeposit(msg.sender, _amount);
        } else {
            SDToken sdToken = SDToken(getReserveSDTokenAddress(_reserve));
            sdToken.mintOnDeposit(msg.sender, _amount);
        }

        //transfer to the core contract
        if (_reserve != EthAddressLib.ethAddress()) {
            require(
                msg.value == 0,
                'User is sending ETH along with the ERC20 transfer.'
            );
            ERC20(_reserve).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        } else {
            require(
                msg.value >= _amount,
                'The amount and the value sent to deposit do not match'
            );

            if (msg.value > _amount) {
                //send back excess ETH
                uint256 excessAmount = msg.value.sub(_amount);
                //solium-disable-next-line
                (bool result, ) = msg.sender.call{value: excessAmount}('');
                require(result, 'Transfer of ETH failed');
            }
        }

        //solium-disable-next-line
        emit Deposit(_reserve, msg.sender, _amount, block.timestamp);
    }

    /**
     * @dev Redeems the underlying amount of assets requested by _user.
     * This function is executed by the overlying aToken contract in response to a redeem action.
     * @param _reserve the address of the reserve
     * @param _tranche the tranche of the reserve
     * @param _user the address of the user performing the action
     * @param _amount the underlying amount to be redeemed
     **/
    function redeemUnderlying(
        address _reserve,
        CoreLibrary.Tranche _tranche,
        address payable _user,
        uint256 _amount,
        uint256 _aTokenBalanceAfterRedeem
    )
        external
        nonReentrant
        onlyOverlyingToken(_reserve)
        onlyActiveReserve(_reserve)
        onlyAmountGreaterThanZero(_amount)
    {
        uint256 currentAvailableLiquidity = getReserveAvailableLiquidity(
            _reserve
        );
        require(
            currentAvailableLiquidity >= _amount,
            'There is not enough liquidity available to redeem'
        );

        updateStateOnRedeem(
            _reserve,
            _tranche,
            _user,
            _amount,
            _aTokenBalanceAfterRedeem == 0
        );

        transferToUser(_reserve, _user, _amount);

        //solium-disable-next-line
        emit RedeemUnderlying(_reserve, _user, _amount, block.timestamp);
    }
}

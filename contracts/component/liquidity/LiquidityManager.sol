// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/ownership/Ownable.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../libraries/CoreLibrary.sol';
import '../../libraries/EthAddressLib.sol';
import '../../interfaces/IReserveInterestRateStrategy.sol';
import '../../tokenization/JuniorDepositToken.sol';
import '../../tokenization/SeniorDepositToken.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import '../../libraries/ReserveManager.sol';

contract LiquidityManager is Ownable, ReentrancyGuard, ReserveManager {
    using CoreLibrary for CoreLibrary.ReserveData;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

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
            JuniorDepositToken jdToken = JuniorDepositToken(
                getReserveJDTokenAddress(_reserve)
            );
            jdToken.mintOnDeposit(msg.sender, _amount);
        } else {
            SeniorDepositToken sdToken = SeniorDepositToken(
                getReserveSDTokenAddress(_reserve)
            );
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

    /**
     * @dev Get security requirement for _reserve
     * @param _reserve the address of the reserve
     **/
    function getSecurityRequirement(address _reserve)
        external
        view
        returns (uint256)
    {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        return reserve.securityRequirement;
    }

    /**
     * @dev Set security requirement for _reserve
     * @param _reserve the address of the reserve
     * @param _value valut of the security requirement
     **/
    function setSecurityRequirement(address _reserve, uint256 _value)
        public
        onlyLendingPoolManager
    {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
        reserve.securityRequirement = _value;
    }
}

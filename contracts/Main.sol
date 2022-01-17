// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.9;

import './libraries/ownership/Ownable.sol';
import './libraries/math/WadRayMath.sol';
import "./libraries/CoreLibrary.sol";
import "./libraries/EthAddressLib.sol";
import './credit/CreditAccount.sol';
import './interfaces/ICreditAccount.sol';
import './tokenization/OToken.sol';
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract Main is Ownable, ReentrancyGuard {

    using CoreLibrary for CoreLibrary.ReserveData;
    using SafeMath for uint256;


       /**
    * @dev emitted when a reserve is initialized.
    * @param _reserve the address of the reserve
    * @param _oToken the address of the overlying aToken contract
    * @param _interestRateStrategyAddress the address of the interest rate strategy for the reserve
    **/
    event ReserveInitialized(
        address indexed _reserve,
        address indexed _oToken,
        address _interestRateStrategyAddress
    );

    /**
    * @dev emitted when a reserve is activated
    * @param _reserve the address of the reserve
    **/
    event ReserveActivated(address indexed _reserve);


    mapping(address => CoreLibrary.ReserveData) _reserves;

    address lendingPoolManager;

    modifier onlyLendingPoolManager {
         require(
            lendingPoolManager == msg.sender,
            "The caller must be a lending pool manager"
        );
        _;
    }

    /**
    * @dev gets the available liquidity in the reserve. The available liquidity is the balance of the core contract
    * @param _reserve the reserve address
    * @return the available liquidity
    **/
    function getReserveAvailableLiquidity(address _reserve) public view returns (uint256) {
        uint256 balance = 0;

        if (_reserve == EthAddressLib.ethAddress()) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_reserve).balanceOf(address(this));
        }
        return balance;
    }


    function initReserveWithData(
        address _reserve,
        string memory _oTokenName,
        string memory _oTokenSymbol,
        uint8 _underlyingAssetDecimals,
        address _interestRateStrategyAddress,
        CoreLibrary.Tranche tranche
    ) public onlyLendingPoolManager {
        OToken oTokenInstance = new OToken (
            _reserve,
            _underlyingAssetDecimals,
            _oTokenName,
            _oTokenSymbol
        );

        _reserves[_reserve].init(
            address(oTokenInstance),
            _underlyingAssetDecimals,
            _interestRateStrategyAddress,
            tranche
        );


        emit ReserveInitialized(
            _reserve,
            address(oTokenInstance),
            _interestRateStrategyAddress
        );

    }


    function initReserve(
        address _reserve,
        uint8 _underlyingAssetDecimals,
        address _interestRateStrategyAddress,
        CoreLibrary.Tranche tranche
    ) external onlyLendingPoolManager {
        ERC20 asset = ERC20(_reserve);
        string memory oTokenName = string(abi.encodePacked("Ownft Interest bearing ", asset.name()));
        string memory oTokenSymbol = string(abi.encodePacked("a", asset.symbol()));
        initReserveWithData(_reserve, oTokenName, oTokenSymbol, _underlyingAssetDecimals, _interestRateStrategyAddress, tranche);
    }

    /**
    * @dev activates a reserve
    * @param _reserve the address of the reserve
    **/
    function activateReserve(address _reserve) external onlyLendingPoolManager {
        CoreLibrary.ReserveData storage reserve = _reserves[_reserve];
         require(
            reserve.lastLiquidityCumulativeIndex > 0,
            "Reserve has not been initialized yet"
        );
        emit ReserveActivated(_reserve);
    }

}
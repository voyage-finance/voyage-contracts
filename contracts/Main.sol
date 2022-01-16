import './libraries/ownership/Ownable.sol';
import './libraries/math/WadRayMath.sol';
import './Deposit.sol';
import './interfaces/IDeposit.sol';
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract Main is Ownable, ReentrancyGuard {

    enum Tranche { JUNIOR, SENIOR }

    struct ReserveData {
        //the liquidity index. Expressed in ray
        uint256 lastLiquidityCumulativeIndex;
        //the current supply rate. Expressed in ray
        uint256 currentLiquidityRate;
        //the total borrows of the reserve at a stable rate. Expressed in the currency decimals
        uint256 totalBorrows;
        //the decimals of the reserve asset
        uint256 decimals;
        /**
        * @dev address of the aToken representing the asset
        **/
        address oTokenAddress;
        /**
        * @dev address of the interest rate strategy contract
        **/
        address interestRateStrategyAddress;
        uint40 lastUpdateTimestamp;
        // isActive = true means the reserve has been activated and properly configured
        bool isActive;
        Tranche tranche;
    }

    mapping(address => ReserveData) _reserves;

    address lendingPoolManager;

    modifier onlyLendingPoolManager {
         require(
            lendingPoolManager == msg.sender,
            "The caller must be a lending pool manager"
        );
        _;
    }


    function initReserveWithData(
        address _reserve,
        string memory _oTokenName,
        string memory _oTokenSymbol,
        uint8 _underlyingAssetDecimals,
        address _interestRateStrategyAddress,
        Tranche tranche
    ) public onlyLendingPoolManager {

    }


    function initReserve(
        address _reserve,
        uint8 _underlyingAssetDecimals,
        address _interestRateStrategyAddress,
        Tranche tranche
    ) external onlyLendingPoolManager {
        ERC20 asset = ERC20(_reserve);
        string memory oTokenName = string(abi.encodePacked("Ownft Interest bearing ", asset.name()));
        string memory oTokenSymbol = string(abi.encodePacked("a", asset.symbol()));
        initReserveWithData(_reserve, oTokenName, oTokenSymbol, _underlyingAssetDecimals, _interestRateStrategyAddress, tranche);
    }

}
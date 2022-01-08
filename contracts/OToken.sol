import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import './libraries/math/WadRayMath.sol';
import './Ownft.sol';

contract OToken is ERC20 {
    using WadRayMath for uint256;

    address public underlyingAssetAddress;

    Ownft private ownft;

    modifier onlyOwnft {
        require(
            msg.sender ==  address(ownft),
            'The caller of this function must be Ownft'
        );
        _;
    }

    constructor(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {

    }

    function mintOnDeposit(address _account, uint256 _amount) external onlyOwnft {
    }


}
// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.9;

import './libraries/ownership/Ownable.sol';
import './libraries/math/WadRayMath.sol';
import './credit/CreditAccount.sol';
import './interfaces/ICreditAccount.sol';
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract Ownft is Ownable, ReentrancyGuard {

    struct Reserve {
        uint256 interest_rate;
        uint last_update_timestamps;
        uint256 last_liquidity_cumulative_index;
        bool enabled;
    }

    // last_update_time will be updated when deposit/claim happens
    struct DepositInfo {
        address user;
        mapping(address => uint) principals;
        mapping(address => uint) last_update_timestamps;
    }

    struct BorrowInfo {
        address deposit_contract;
        address token;
        uint principal;
        uint last_update_timestamp;
    }


    using Address for address;
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using WadRayMath for uint256;

    event UserDeposit(
        address _token,
        address _user,
        uint256 _amount,
        uint256 _timestamp
    );

    event WhilteListToken(
        address _token,
        bool _enable,
        address _operator
    );

    event WhiteListNFT(
        address _nft,
        bool _enable,
        address _operator
    );

    event InterestRateSet(
        address token,
        uint256 _interest_rate,
        address _operator
    );

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    mapping(address => bool) _nftWhitelist;

    // token => interest rate, expressed in ray
    mapping(address => Reserve) _reserves;

    // borrower address => borrow info
    mapping(address => BorrowInfo) _borrowers;

    // investor address => user info
    mapping(address => DepositInfo) _depositInfo;

    // nft address => lending token address
    mapping(address => address) _lending_tokens;

    constructor() public {
    }

    function calculateLinearInterest(
        uint256 principal,
        uint256 _rate,
        uint256 _lastUpdateTimestamp
    )
        internal
        view
        returns (uint256)
    {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp.sub(_lastUpdateTimestamp);

        uint256 timeDelta = timeDifference.wadToRay().rayDiv(SECONDS_PER_YEAR.wadToRay());

        return _rate.rayMul(timeDelta).mul(principal);
    }

    // set up assets that can be deposited
    function setDepositWhiteList(
        address token,
        bool enable
    ) onlyOwner external {
        Reserve storage reserve = _reserves[token];
        reserve.enabled = enable;
        emit WhilteListToken(token, enable, msg.sender);
    }

    function setNFTWhiteList(
        address nft,
        bool enable
    ) onlyOwner external {
        _nftWhitelist[nft] = enable;
        emit WhiteListNFT(nft, enable, msg.sender);
    }

    function setInvestorInterestRate(
        address token,
        uint256 interest_rate
    ) onlyOwner external {
        Reserve storage reserve = _reserves[token];
        reserve.interest_rate = interest_rate;
        emit InterestRateSet(msg.sender, interest_rate, msg.sender);
    }

    function createDepositContract(
        address user,
        address owner
    ) internal returns (address) {
      bytes memory bytecode = type(Deposit).creationCode;
      bytes32 salt = keccak256(abi.encodePacked(user));
      address d;
      assembly {
          // derived from uniswap contract
          // todo test this carefully
        d := create2(0, add(bytecode, 32), mload(bytecode), salt)
      }
      ICreditAccount(d).initialize(user);
      return d;
    }

    function deposit(
        address token,
        uint amount
    ) external nonReentrant {
        //require(_depositWhitelist[token] == true, 'Ownft: TOKEN NOT ENABLED');
        //require(_investor_interest[token] > 0, 'Ownft: TOKEN INTEREST RATE NOT SET');
        // update user state
        // DepositInfo storage user = _depositInfo[msg.sender];
        // if (user.principals[token] > 0) {
        //     uint256 pending_rewards = calculateLinearInterest(user.principals[token], _investor_interest[token], user.last_update_timestamps[token]);
        //     ERC20(token).safeTransfer(msg.sender, pending_rewards);
        // }
        // ERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        // user.principals[token] += amount;
        // user.last_update_timestamps[token] = block.timestamp;
        emit UserDeposit(token, msg.sender, amount, block.timestamp);
    }

    function borrow(
        address nft
    ) external nonReentrant {
        require(_nftWhitelist[nft] == true, 'Ownft: NFT NOT ENABLED');
        BorrowInfo storage borrower = _borrowers[msg.sender];
        require(borrower.principal > 0, 'Ownft: INVALID BORROWER');
        // 1. transfer some of our token as collateral

        // todo how much we should transfer
        uint lendingAmount = 0;
        address lendingToken = _lending_tokens[nft];
        // 2. update state
        borrower.principal += lendingAmount;
        borrower.last_update_timestamp = block.timestamp;
        borrower.token = lendingToken;

        // 3. deploy deposit contract
        address depositContract = createDepositContract(msg.sender, address(this));
        borrower.deposit_contract = depositContract;

        // 4. transfer token to the deposit contract
        ERC20(lendingToken).safeTransfer(depositContract, lendingAmount);
    }
}
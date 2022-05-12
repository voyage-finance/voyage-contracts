// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/**
 * @title IDepositToken
 * @notice Interface for the initialize function on JuniorDepositToken and SeniorDepositToken
 **/
abstract contract IInitializableDepositToken {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    // user address => timestamp => amount
    mapping(address => mapping(uint256 => uint256)) private withdrawals;

    // user address => timestamp array
    mapping(address => uint256[]) private pendingTimestamp;

    uint256 private totalPending;

    uint256 private lockupTime = 7 days;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing ||
                isConstructor() ||
                revision > lastInitializedRevision,
            'Contract instance has already been initialized'
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /**
     * @dev returns the revision number of the contract
     * Needs to be defined in the inherited class as a constant.
     **/
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @dev Emitted when an depositToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param liquidityManagerProxy The address of the associated liquidity manager proxy
     * @param tokenDecimals the decimals of the underlying
     * @param tokenName the name of the depositToken
     * @param tokenSymbol the symbol of the depositToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed liquidityManagerProxy,
        uint8 tokenDecimals,
        string tokenName,
        string tokenSymbol,
        bytes params
    );

    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Returns true if the contract has been initialized
     **/
    function isInitialized() public view returns (bool) {
        return !initializing && getRevision() <= lastInitializedRevision;
    }

    /**
     * @dev Returns true if and only if the function is running in the constructor
     **/
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;

    function pushWithdraw(address _user, uint256 _amount) internal {
        require(withdrawals[_user][block.timestamp] == 0, 'invalid withdraw');
        withdrawals[_user][block.timestamp] = _amount;
        pendingTimestamp[_user].push(block.timestamp);
        totalPending += _amount;
    }

    function popWithdraw(address _user, uint256 _index)
        internal
        returns (uint256)
    {
        uint256[] storage times = pendingTimestamp[_user];
        require(_index < times.length, 'invalid index');
        uint256 ts = times[_index];
        require(block.timestamp - ts > lockupTime, 'cool down error');

        uint256 last = times[times.length - 1];
        times[_index] = last;
        times.pop();

        uint256 withdrawable = withdrawals[_user][ts];
        delete withdrawals[_user][ts];
        totalPending -= withdrawable;
        return withdrawable;
    }

    function pendingWithdrawal(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return pendingTimestamp[_user];
    }

    function totalPendingWithdrawal() public view returns (uint256) {
        return totalPending;
    }

    function withdrawalAble(address _user) public view returns (uint256) {
        uint256[] storage ts = pendingTimestamp[_user];
        uint256 withdrawable = 0;

        for (uint256 i = 0; i < ts.length; i++) {
            withdrawable += withdrawals[_user][ts[i]];
        }
        return withdrawable;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IStableDebtToken {
    /**
     * @dev Emitted when new stable debt is minted
     * @param user The address of the user who triggered the minting
     * @param amount The amount minted (user entered amount + balance increase from interest)
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param newRate The rate of the debt after the minting
     * @param avgStableRate The next average stable rate after the minting
     * @param newTotalSupply The next total supply of the stable debt token after the action
     **/
    event Mint(
        address indexed user,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 newRate,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    function mint(
        address _user,
        uint256 _amount,
        uint256 _tenure,
        uint256 _rate
    ) external virtual;

    function burn(
        address _user,
        uint256 _drawDown,
        uint256 _amount
    ) external virtual;

    function getAverageStableRate() external view returns (uint256);

    function getTotalSupplyAndAvgRate()
        external
        view
        returns (uint256, uint256);

    function getAggregateOptimalRepaymentRate(address _user)
        external
        view
        returns (uint256);

    function getAggregateActualRepaymentRate(address _user)
        external
        view
        returns (uint256);

    function balanceOfDrawdown(address _account, uint256 _drawDown)
        external
        view
        returns (uint256);
}

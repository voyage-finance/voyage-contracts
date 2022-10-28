// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IConfigurationFacet {
    function setLiquidationBonus(address _collection, uint256 _liquidationBonus)
        external;

    function setIncomeRatio(address _collection, uint256 _ratio) external;

    function setOptimalLiquidityRatio(address _collection, uint256 _ratio)
        external;

    function setMaxTwapStaleness(address _collection, uint256 _maxTwapStaleness)
        external;

    function setLoanParams(
        address _collection,
        uint256 _epoch,
        uint256 _term,
        uint256 _gracePeriod
    ) external;

    function setGSNConfiguration(address _paymaster, address _trustedForwarder)
        external;

    function setInterestRateStrategyAddress(
        address _reserve,
        address _interestRateStrategyAddress
    ) external;

    function updateMarketPlaceData(address _marketplace, address _strategy)
        external;

    function upgradeJuniorDepositTokenImpl(address _impl) external;

    function upgradeSeniorDepositTokenImpl(address _impl) external;

    function setOracleSigner(address _signer) external;

    function getOracleSigner() external view returns (address);

    function setTwapTolerance(address _collection, uint256 _twapTolerance)
        external;
}

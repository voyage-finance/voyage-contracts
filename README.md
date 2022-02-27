# ownft-contracts

## Openzeppelin ERC721

https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721


## Architecture

![contract architecture](https://github.com/halcyon-project/ownft-contracts/blob/main/doc/arch.ipg)

## Specification

### Voyager

### LiquidityManager

| Name                     | Description                                                                                                                                            | Modifier             | Parameters                                                                                                                                                                                                                                 |
|--------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `initReserveWithData`    | init a reserve                                                                                                                                         | `onlyVoyager`        | `address _reserve, string memory _jdTokenName, string memory _jdTokenSymbol, string memory _sdTokenName, string memory _sdTokenSymbol, uint8 _underlyingAssetDecimals, address _interestRateStrategyAddress, uint256 _securityRequirement` |
| `activateReserve`        | activates a reserve                                                                                                                                    | `onlyVoyager`        | `address _reserve`                                                                                                                                                                                                                         |                                                                                                                                                                                                          |
| `deactivateReserve`      | deactivates a reserve                                                                                                                                  | `onlyVoyager`        | `address _reserve`                                                                                                                                                                                                                         |                                                                                                                                                                                                                        |
| `depositLiquidity`       | depositLiquidity The underlying asset into the reserve. A corresponding amount of the overlying asset is minted.                                       | `onlyVoyager`        | ` address _reserve， CoreLibrary.Tranche _tranche, uint256 _amount`                                                                                                                                                                         |                                                                                                                                                                        |
| `redeemUnderlying`       | Redeems the underlying amount of assets requested by _user. This function is executed by the overlying aToken contract in response to a redeem action. | `onlyOverlyingToken` | ` address _reserve, CoreLibrary.Tranche _tranche, address payable _user, uint256 _amount, uint256 _aTokenBalanceAfterRedeem`                                                                                                               |                                                                                                                                                                        |
| `getSecurityRequirement` | Get security requirement for _reserve.                                                                                                                 | `public`             | ` address _reserve`                                                                                                                                                                                                                        |                                                                                                                                                                        |
| `setSecurityRequirement` | Set security requirement for _reserve.                                                                                                                 | `onlyVoyager`        | ` address _reserve, uint256 _value`                                                                                                                                                                                                        |                                                                                                                                                                        |

### LoanManager

### VaultManager

| Name                  | Description                                    | Modifier      | Parameters        |
|-----------------------|------------------------------------------------|---------------|-------------------|
| `createAccount`       | Create a credit account                        | `onlyVoyager` | `address _player` |
| `createAccount`       | Create a credit account                        | `onlyVoyager` | `address _player` |
| `getCreditAccount`    | Get credit account address for a specific user | `public`      | `address _user`   |
| `getAllCreditAccount` | Get all credit account addresses               | `public`      | ``                |
# Voyage
[![Hardhat CI](https://github.com/voyage-finance/voyage-contracts/actions/workflows/hardhat-test.yml/badge.svg?branch=main)](https://github.com/voyage-finance/voyage-contracts/actions/workflows/hardhat-test.yml)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/b267ea2078424f5b927060006ca5c66b)](https://www.codacy.com?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=voyage-finance/voyage-contracts&amp;utm_campaign=Badge_Grade)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/b267ea2078424f5b927060006ca5c66b)](https://www.codacy.com?utm_source=github.com&utm_medium=referral&utm_content=voyage-finance/voyage-contracts&utm_campaign=Badge_Coverage)

## Architecture

![contract architecture](https://github.com/halcyon-project/voyage-contracts/blob/main/doc/voyage_arch.png)

## Docker

There is a docker image available for use.

```shell
# in the repository root
yarn build:docker

# to run on port 8545 with deploy
docker run -d -it --rm --name hh-voyage -p 8545:8545 596511190950.dkr.ecr.us-west-2.amazonaws.com/voyage-core-contracts:latest

# to run on port 8545 without deploying contracts
docker run -d -it --rm --name hh-voyage -p 8545:8545 596511190950.dkr.ecr.us-west-2.amazonaws.com/voyage-core-contracts:latest 'node'
```

## Specification

### Voyager

Constants:

```solidity
    bytes32 public constant liquidityManagerName = 'liquidityManager';
    bytes32 public constant loanManagerName = 'loanManager';
    bytes32 public constant vaultManagerName = 'vaultManager';
    bytes32 public constant vaultStorageName = 'vaultStorage';
```

| Name                        | Description                             | Parameters                 | Modifier    |
| --------------------------- | --------------------------------------- | -------------------------- | ----------- |
| `setAddressResolverAddress` | Update addressResolver contract address | `address _addressResolver` | `onlyOwner` |
| `getAddressResolverAddress` | Get addressResolver contract address    |                            | `public`    |
| `createVault`               | Create an empty Vault for user          |                            | `public`    |


### Escrow


| Name        | Description                                                                | Parameters                                         | Modifier    |
| ----------- | -------------------------------------------------------------------------- | -------------------------------------------------- | ----------- |
| `deposit`   | Stores the sent amount as credit to be withdrawn                           | `address _reserve, address _user, uint256 _amount` | `onlyOwner` |
| `withdraw ` | Withdraw accumulated balance for a payee, only beyond _lockupTimeInSeconds | `address _reserve, address _user, uint256 _amount` | `onlyOwner` |

### AddressResolver

| Name                   | Description                                                                  | Modifier    | Parameters                                                  |
| ---------------------- | ---------------------------------------------------------------------------- | ----------- | ----------------------------------------------------------- |
| `importAddresses`      | import addresses of contracts                                                | `onlyOwner` | `bytes32[] calldata names, address[] calldata destinations` |
| `getAddress`           | get address of a specific named contract                                     | `public`    | `bytes32 name`                                              |
| `requireAndGetAddress` | get address of a specific named contract, throw error if the address is zero | `public`    | `bytes32 name, string calldata reason`                      |

### LiquidityManager

#### Functions

| Name                     | Description                                                                                                                                            | Modifier             | Parameters                                                                                                                                                                                                                                 |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `initReserve`            | init a reserve                                                                                                                                         | `onlyVoyager`        | `address _reserve, uint8 _underlyingAssetDecimals, address _interestRateStrategyAddress, uint256 _securityRequirement`                                                                                                                     |
| `initReserveWithData`    | init a reserve                                                                                                                                         | `onlyVoyager`        | `address _reserve, string memory _jdTokenName, string memory _jdTokenSymbol, string memory _sdTokenName, string memory _sdTokenSymbol, uint8 _underlyingAssetDecimals, address _interestRateStrategyAddress, uint256 _securityRequirement` |
| `activateReserve`        | activates a reserve                                                                                                                                    | `onlyVoyager`        | `address _reserve`                                                                                                                                                                                                                         |  |
| `deactivateReserve`      | deactivates a reserve                                                                                                                                  | `onlyVoyager`        | `address _reserve`                                                                                                                                                                                                                         |  |
| `depositLiquidity`       | depositLiquidity The underlying asset into the reserve. A corresponding amount of the overlying asset is minted.                                       | `onlyVoyager`        | ` address _reserve， CoreLibrary.Tranche _tranche, uint256 _amount`                                                                                                                                                                        |  |
| `redeemUnderlying`       | Redeems the underlying amount of assets requested by _user. This function is executed by the overlying aToken contract in response to a redeem action. | `onlyOverlyingToken` | ` address _reserve, CoreLibrary.Tranche _tranche, address payable _user, uint256 _amount, uint256 _aTokenBalanceAfterRedeem`                                                                                                               |  |
| `getSecurityRequirement` | Get security requirement for _reserve.                                                                                                                 | `public`             | ` address _reserve`                                                                                                                                                                                                                        |  |
| `setSecurityRequirement` | Set security requirement for _reserve.                                                                                                                 | `onlyVoyager`        | ` address _reserve, uint256 _value`                                                                                                                                                                                                        |  |

### LoanManager

### VaultManager

#### Mutable Fields

| Name        | Type        | Description                      |
| ----------- | ----------- | -------------------------------- |
| `allVaults` | `address[]` | Address array contains all vault |
| `voyager`   | `address`   | voyager contract address         |

### VaultStorage

#### Functions

| Name              | Description                                    | Modifier      | Parameters        |
| ----------------- | ---------------------------------------------- | ------------- | ----------------- |
| `createAccount`   | Create a credit account                        | `onlyVoyager` | `address _player` |
| `getVaultAddress` | Get credit account address for a specific user | `public`      | `address _user`   |
| `getAllVaults`    | Get all credit account addresses               | `public`      |                   |


### StakingRewards

While sponsors do the security deposit, they will get back `SecurityDepsitToken` in return, which can be staked and earn rewards.

#### Functions

| Name | Description | Modifier | Parameters |
| ---- | ----------- | -------- | ---------- |

## Reference

### Openzeppelin ERC721

https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721

### ACL

https://docs.openzeppelin.com/contracts/4.x/access-control

https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/AccessControl.sol

### Synthetix Staking

https://github.com/Synthetixio/synthetix/blob/e53c9c05e1fdf8e530143e9dd843846638538bde/contracts/StakingRewards.sol

### Synthetix Proxy

https://docs.synthetix.io/contracts/source/contracts/Proxy/

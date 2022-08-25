██╗░░░██╗░█████╗░██╗░░░██╗░█████╗░░██████╗░███████╗
██║░░░██║██╔══██╗╚██╗░██╔╝██╔══██╗██╔════╝░██╔════╝
╚██╗░██╔╝██║░░██║░╚████╔╝░███████║██║░░██╗░█████╗░░
░╚████╔╝░██║░░██║░░╚██╔╝░░██╔══██║██║░░╚██╗██╔══╝░░
░░╚██╔╝░░╚█████╔╝░░░██║░░░██║░░██║╚██████╔╝███████╗
░░░╚═╝░░░░╚════╝░░░░╚═╝░░░╚═╝░░╚═╝░╚═════╝░╚══════╝

# Voyage
[![Hardhat CI](https://github.com/voyage-finance/voyage-contracts/actions/workflows/hardhat-test.yml/badge.svg?branch=main)](https://github.com/voyage-finance/voyage-contracts/actions/workflows/hardhat-test.yml)

## Architecture

![contract architecture](https://github.com/halcyon-project/voyage-contracts/blob/main/doc/voyage_arch.png)

## Getting started

1. To run deploy and run the contracts against a local hardhat node:

```shell
# runs hardhat in automine mode and runs all deployments.
yarn node:deploy
# or in interval mode
yarn node:deploy:interval
```

This should listen on `localhost:8545` as expected.

2. To fork from a testnet (e.g. rinkeby) state, following the current steps:

```shell
1. yarn run node --fork https://eth-rinkeby.alchemyapi.io/v2/2rkHcv3Pdg7j3iHPWUu9cDsEOtSoXtoB this command runs a node without deploying any contracts to it wiht the current Rinkeby state

2. yarn run deploy:local to redeploy voyage contracts to the local node
```

## Run scripts

There is a runner that helps run scripts automatically with nice logs.

```shell
yarn hardhat run scripts 
```

If you need to run these scripts against a network that is not `localhost`, ensure to set your private key by executing:

```shell
DEPLOYER_PRIVATE_KEY=<0xsecret> yarn scripts
```

## Specification

### Voyage

Base on EIP-2535, Voyage is the contract that uses functions from its facets (see the next section) to execute calls. It is the entry point of the Voyage protocol.

### Facets

#### liquidityFacet

Manage liquidity pool, provide interfaces for users to deposit and withdraw currency to/from liquidity pools.

| Name                   | Description                                                                  | Modifier    | Parameters                                                  |
| ---------------------- | ---------------------------------------------------------------------------- | ----------- | ----------------------------------------------------------- |
| `initReserve`      | Init a new reserve | `authorised` | `address _collection, address _currency, address _interestRateStrategyAddress, address _priceOracle` |
| `activateReserve`      | Active a reserve | `authorised` | `address _collection` |
| `updateProtocolFee`      | Update treasury address and cut ratio | `authorised` | `address _treasuryAddr, uint40 _cutRatio` |
| `upgradePriceOracleImpl`      | Update the implementation address of PriceOracle contract, see [UpgradeableBeacon](https://docs.openzeppelin.com/contracts/3.x/api/proxy) pattern | `authorised` | `address _collection, address _priceOracle` |
| `updateWETH9`      | Update weth9 contract address | `authorised` | `address _weth9` |
| `deposit`      | Deposit liquidity to a specific pool base on collection address | `N/A` | `address _collection, Tranche _tranche, uint256 _amount` |
| `withdraw`      | Withdraw liquidity from a specific pool base on collection address | `N/A` | `address _collection, Tranche _tranche, uint256 _amount` |

#### LoanFacet

Manage NFT purchasing, debt repayment and liquidation.

| Name                   | Description                                                                  | Modifier    | Parameters                                                  |
| ---------------------- | ---------------------------------------------------------------------------- | ----------- | ----------------------------------------------------------- |
| `buyNow`      | Buy a specific NFT from a choosing marketplace | `nonReentrant` | `address _collection, uint256 _tokenId, address payable _vault, bytes calldata _data` |
| `repay`      | Repay a specific debt | `nonReentrant` | `address _collection, uint256 _loan, address payable _vault` |
| `liquidate`      | Liquidate a bad debt | `nonReentrant` | `address _collection, address _vault, uint256 _loanId` |

#### VaultFacet

Manage vault creation, delegate calls to vaults.

| Name                   | Description                                                                  | Modifier    | Parameters                                                  |
| ---------------------- | ---------------------------------------------------------------------------- | ----------- | ----------------------------------------------------------- |
| `createVault`      | Create a vault using create2 | `authorised` | `address _user, bytes20 _salt` |
| `withdrawNFT`      | Delegate call to vault contract to withdraw a specific NFT | `nonReentrant` | `address _vault, address _collection, uint256 _tokenId` |
| `transferReserve`      | Delegate call to vault contract to transfer reserve | `nonReentrant` | `address _vault, address _currency, address _to, uint256 _amount` |

#### SecurityFacet

Provides a flexible and updatable auth pattern which is completely separate from application logic. Refer https://github.com/dapphub/ds-auth

#### ConfigurationFacet

Set protocol variables.

| Name                   | Description                                                                  | Modifier    | Parameters                                                  |
| ---------------------- | ---------------------------------------------------------------------------- | ----------- | ----------------------------------------------------------- |
| `setLiquidationBonus`      | Set liquidation bonus using by liquidate function | `authorised` | `address _collection, uint256 _liquidationBonus` |
| `setIncomeRatio`      | Set income ration for allocating incoming interest | `authorised` | `address _collection, uint256 _ratio` |
| `setLoanParams`      | Set loan params such as epoch, term and grace period | `authorised` | `address _collection, uint256 _epoch, uint256  _term, uint256 _gracePeriod` |

#### MarketplaceAdapterFacet

Delegate NFT purchasing to different marketplace. See Adapters section.

| Name                   | Description                                                                  | Modifier    | Parameters                                                  |
| ---------------------- | ---------------------------------------------------------------------------- | ----------- | ----------------------------------------------------------- |
| `purchase`      | Purchase a NFT from a supported marketplace | `N/A` | `address _marketplace, address _vault, bytes calldata _data` |

### Adapters

Adapters are contracts that saperate from the main protocol logic but provide essential functions such as buying NFT from outside protocols. Voyage protocol currently provides two adapters:

1. LooksRareAdapter for purchasing NFT from [LooksRare](https://looksrare.org/)

2. SeaportAdapter for purchasing NFT from [OpenSea](https://opensea.io/)

As the protocol grows over time, more adapters might be added, and all adapters should implemetate interface as follows:

```solidity
interface IMarketPlaceAdapter {
    function extractAssetPrice(bytes calldata _data)
        external
        pure
        returns (uint256);

    function validate(bytes calldata _data) external view returns (bool);

    function execute(bytes calldata _data) external view returns (bytes memory);
}
```


### Price Oracle

Voyage protocol uses a centralized way to provide on-chain price for now, A offchain service is authorised to feed prices to the oracle contract using:

```solidity
    function updateTwap(address _currency, uint256 _priceAverage)
        external
        auth
    {
        prices[_currency].priceAverage = _priceAverage;
        prices[_currency].blockTimestamp = block.timestamp;
    }
```

Any contract within voyage protocol can access price data through:

```solidity
    function getTwap(address _currency)
        external
        view
        returns (uint256, uint256)
    {
        return (
            prices[_currency].priceAverage,
            prices[_currency].blockTimestamp
        );
    }
```

## Reference

### Openzeppelin ERC721

https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721

### EIP-2535

https://eips.ethereum.org/EIPS/eip-2535

### DSAuth

https://github.com/dapphub/ds-auth

### GSN

https://docs.opengsn.org/

import { ethers, getNamedAccounts, deployments } from 'hardhat';
import { PriceOracle, Voyage } from '@contracts';

async function main() {
  const { owner, alice } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const vaultAddress = await voyage.getVault(owner);
  const weth = await ethers.getContract('WETH9');
  const crab = await ethers.getContract('Crab');
  const marketPlace = await ethers.getContract('MockMarketPlace');
  const looksRareAdapter = await ethers.getContract('LooksRareAdapter');
  await voyage.updateMarketPlaceData(
    marketPlace.address,
    looksRareAdapter.address
  );
  const priceOracle = await ethers.getContract<PriceOracle>('PriceOracle');
  console.log('vault address: ', vaultAddress);
  await priceOracle.updateTwap(crab.address, 300);
  const abiCoder = ethers.utils.defaultAbiCoder;
  const looksRareMakerOrderData = abiCoder.encode(
    [
      'bool',
      'address',
      'address',
      'uint256',
      'uint256',
      'uint256',
      'address',
      'address',
      'uint256',
      'uint256',
      'uint256',
      'uint256',
      'bytes',
      'uint8',
      'bytes32',
      'bytes32',
    ],
    [
      true,
      owner,
      crab.address,
      1000,
      1,
      1,
      alice,
      weth.address,
      1,
      1,
      1,
      1,
      ethers.utils.arrayify('0x1234'),
      1,
      ethers.utils.arrayify(
        '0x66fdd5e25ef9ddb305ba3c2aae1856ab9c6f2979000000000000000000000000'
      ),
      ethers.utils.arrayify(
        '0x66fdd5e25ef9ddb305ba3c2aae1856ab9c6f2979000000000000000000000000'
      ),
    ]
  );
  const floorPrice = '100';
  const takerOrderData = abiCoder.encode(
    ['bool', 'address', 'uint256', 'uint256', 'uint256', 'bytes'],
    [
      true,
      vaultAddress,
      floorPrice,
      1,
      1,
      ethers.utils.arrayify(
        '0x66fdd5e25ef9ddb305ba3c2aae1856ab9c6f2979000000000000000000000000'
      ),
    ]
  );
  const purchaseDataFromLooksRare = abiCoder.encode(
    ['address', 'bytes4', 'bytes', 'bytes'],
    [marketPlace.address, '0xb4e4b296', looksRareMakerOrderData, takerOrderData]
  );
  const { execute } = deployments;
  await execute(
    'Voyage',
    {
      from: owner,
      log: true,
      gasLimit: 12450000,
    },
    'buyNow',
    crab.address,
    1,
    vaultAddress,
    marketPlace.address,
    purchaseDataFromLooksRare
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

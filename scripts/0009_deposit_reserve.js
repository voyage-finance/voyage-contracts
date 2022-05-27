const hre = require('hardhat');
const { MAX_UINT_256, WAD } = require('../helpers/math');
const BigNumber = require('bignumber.js');
const {
  JR_TOKEN_NAME,
  SR_TOKEN_NAME,
  grantAllowance,
} = require('../helpers/contract');
const { ethers, getNamedAccounts } = hre;

async function main() {
  const { owner } = await getNamedAccounts();
  const voyager = await ethers.getContract('Voyager', owner);
  const tus = await ethers.getContract('Tus', owner);
  const depositAmount = new BigNumber(500_000).multipliedBy(WAD).toFixed();
  await grantAllowance();
  await voyager.deposit(tus.address, '1', depositAmount);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

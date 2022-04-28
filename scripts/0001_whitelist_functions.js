require('dotenv').config();

const hre = require('hardhat');
const { ethers } = hre;

async function main() {
  const { owner } = await hre.getNamedAccounts();
  const Voyager = await ethers.getContract('Voyager', owner);
  await Voyager.whitelistFunction([
    ethers.utils.formatBytes32String('createVault'),
    ethers.utils.formatBytes32String('depositSecurity'),
    ethers.utils.formatBytes32String('redeemSecurity'),
    ethers.utils.formatBytes32String('borrow'),
  ]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

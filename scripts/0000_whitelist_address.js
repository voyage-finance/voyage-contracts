require('dotenv').config();

const hre = require('hardhat');

async function main() {
  const { owner } = await hre.getNamedAccounts();
  const Voyager = await hre.ethers.getContract('Voyager', owner);
  await Voyager.whitelistAddress([owner]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

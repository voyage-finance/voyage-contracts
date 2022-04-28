const hre = require('hardhat');

async function main() {
  const { owner } = await hre.getNamedAccounts();
  const Voyager = await hre.ethers.getContract('Voyager', owner);
  const Tus = await hre.ethers.getContract('Tus', owner);

  const escrowContract =
    await Voyager.getLiquidityManagerEscrowContractAddress();
  await Tus.increaseAllowance(escrowContract, '100000000000000000000');

  console.log('liquidity escrow contract address: ', escrowContract);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

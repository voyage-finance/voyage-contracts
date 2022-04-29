const hre = require('hardhat');
const { ethers, getNamedAccounts } = hre;

async function main() {
  const { owner } = await getNamedAccounts();
  const voyager = await ethers.getContract('Voyager', owner);
  const escrowContract =
    await voyager.getLiquidityManagerEscrowContractAddress();
  console.log('liquidity escrow contract address: ', escrowContract);
  const tus = await ethers.getContract('Tus', owner);
  await tus.increaseAllowance(escrowContract, '500000000000000000000');
  await voyager.deposit(tus.address, '1', '500000000000000000000', owner);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

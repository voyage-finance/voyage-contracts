const hre = require('hardhat');
const { deployments, ethers, getNamedAccounts } = hre;

const getAddress = (contract) =>
  hre.deployments.get(contract).then(({ address }) => address);

async function main() {
  const { owner } = await getNamedAccounts();
  const voyager = await ethers.getContract('Voyager', owner);

  const tus = await deployments.get('Tus');

  await voyager.withdraw(tus.address, '1', '10000000000000000000');

  /*
  const SeniorDepositToken = await ethers.getContract('SeniorDepositToken');
  const [times, amounts] = await SeniorDepositToken.pendingWithdrawal(owner);
  
  console.log("pending times", times);
  console.log("pending amounts", amounts);
  */
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

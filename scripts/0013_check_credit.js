const hre = require('hardhat');
const { deployments, ethers, getNamedAccounts } = hre;

async function main() {
  const { owner } = await getNamedAccounts();
  const vaultManagerProxy = await ethers.getContract(
    'VaultManagerProxy',
    owner
  );
  const tus = await deployments.get('Tus');
  const currentSecurityDeposit = await vaultManagerProxy.getSecurityDeposit(
    owner,
    tus.address
  );
  console.log('current security deposit: ', currentSecurityDeposit.toString());

  const voyager = await ethers.getContract('Voyager', owner);
  const creditLimit = await voyager.getCreditLimit(owner, tus.address);
  console.log('credit limit: ', creditLimit.toString());

  const availableCreditLimit = await voyager.getAvailableCredit(
    owner,
    tus.address
  );
  console.log('available credit limit: ', availableCreditLimit.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

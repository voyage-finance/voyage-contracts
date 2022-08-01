import { Voyage } from '@contracts';
import { logger } from 'ethers';
import { ethers, getNamedAccounts } from 'hardhat';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const vaultAddress = await voyage.getVault(owner);

  const tus = await ethers.getContract('Tus', owner);
  const crab = await ethers.getContract('Crab');
  const balance = await tus.balanceOf(vaultAddress);
  logger.info('balance: %s', balance.toString());
  const currentSecurityDeposit = await voyage.getMargin(
    vaultAddress,
    tus.address
  );
  console.log('current security deposit: ', currentSecurityDeposit.toString());

  const creditLimit = await voyage.getCreditLimit(vaultAddress, crab.address);
  console.log('credit limit: ', creditLimit.toString());
  const availableCreditLimit = await voyage.getAvailableCredit(
    vaultAddress,
    crab.address
  );
  console.log('available credit limit: ', availableCreditLimit.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

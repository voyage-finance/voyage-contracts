import { Voyager } from '@contracts';
import { logger } from 'ethers';
import { ethers, getNamedAccounts } from 'hardhat';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyager = await ethers.getContract<Voyager>('Voyager');
  const vaultAddress = await voyager.getVault(owner);

  const tus = await ethers.getContract('Tus', owner);
  const balance = await tus.balanceOf(vaultAddress);
  logger.info('balance: %s', balance.toString());
  const currentSecurityDeposit = await voyager.getMargin(
    vaultAddress,
    tus.address
  );
  console.log('current security deposit: ', currentSecurityDeposit.toString());

  const creditLimit = await voyager.getCreditLimit(vaultAddress, tus.address);
  console.log('credit limit: ', creditLimit.toString());
  const availableCreditLimit = await voyager.getAvailableCredit(
    vaultAddress,
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

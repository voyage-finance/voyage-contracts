import { Voyage } from '@contracts';
import { formatRay, formatWad } from '@helpers/math';
import { task } from 'hardhat/config';

task(
  'dev:loans',
  'Print all outstanding loans for the specified reserve and vault.'
)
  .addOptionalParam('collection', 'The collection. Defaults to Mocked Crab.')
  .addOptionalParam(
    'vault',
    'The vault address to query. Defaults to owner vault.'
  )
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const defaultCollection = await ethers.getContract('Crab');
    const defaultVault = await voyage.getVault(owner);
    const { vault, collection } = params;
    const creditLineData = await voyage.getCreditLineData(
      vault ?? defaultVault,
      collection ?? defaultCollection.address
    );
    const queries = [];
    const { head, tail } = creditLineData.loanList;
    for (let i = head; i < tail; i++) {
      queries.push(
        voyage.getLoanDetail(
          vault ?? defaultVault,
          collection ?? defaultCollection.address,
          i
        )
      );
    }
    const loans = await Promise.all(queries);
    const formatted = loans.map((loan, idx) => {
      const {
        principal,
        interest,
        term,
        epoch,
        nper,
        apr,
        borrowAt,
        nextPaymentDue,
        totalPrincipalPaid,
        totalInterestPaid,
        paidTimes,
      } = loan;
      return {
        id: head + idx,
        principal: formatWad(principal),
        interest: formatWad(interest),
        term: term.toString(),
        epoch: epoch.toString(),
        nper: nper.toString(),
        apr: formatRay(apr),
        borrowAt: borrowAt.toString(),
        nextPaymentDue: nextPaymentDue.toString(),
        totalPrincipalPaid: formatWad(totalPrincipalPaid),
        totalInterestPaid: formatWad(totalInterestPaid),
        paidTimes: paidTimes.toString(),
      };
    });
    console.log(
      `fetched loans for vault ${vault ?? defaultVault} and collection ${
        collection ?? defaultCollection.address
      }: \n`,
      formatted
    );
  });

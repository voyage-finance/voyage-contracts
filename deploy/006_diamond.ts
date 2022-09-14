import { getDefaultABIs, mergeABIs } from '@helpers/diamond';
import { DeployFunction } from 'hardhat-deploy/types';

const main: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, save } = deployments;
  const { owner } = await getNamedAccounts();
  const diamond = await deploy('Voyage', {
    contract: 'contracts/voyage/Voyage.sol:Voyage',
    deterministicDeployment: true,
    from: owner,
    log: true,
    args: [owner],
  });
  const coreFacetABIs = await getDefaultABIs();
  const diamondABI = mergeABIs(coreFacetABIs, {
    check: true,
    skipSupportsInterface: false,
  });
  await save('Voyage', { ...diamond, abi: diamondABI });
};

main.tags = ['Diamond'];

export default main;

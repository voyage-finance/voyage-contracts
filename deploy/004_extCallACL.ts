import { DeployFunction } from 'hardhat-deploy/types';

const ExtCallACL = 'ExtCallACL';
const ExtCallACLProxy = 'ExtCallACLProxy';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();

  const ExtCallAclProxy = await deploy(ExtCallACLProxy, {
    from: owner,
    log: true,
  });

  const ExtCallAcl = await deploy(ExtCallACL, {
    from: owner,
    args: [ExtCallAclProxy.address],
    log: true,
  });

  await execute(
    'ExtCallACLProxy',
    { from: owner, log: true },
    'setTarget',
    ExtCallAcl.address
  );

};

deployFn.tags = ['ExtCallAcl'];

export default deployFn;

import { DeployFunction } from 'hardhat-deploy/types';

const ExtCallACL = 'ExtCallACL';
const ExtCallACLProxy = 'ExtCallACLProxy';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();

  const AddressResolver = await deployments.get('AddressResolver');

  const ExtCallAclProxy = await deploy(ExtCallACLProxy, {
    from: owner,
    args: [AddressResolver.address],
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
deployFn.dependencies = ['AddressResolver'];

export default deployFn;

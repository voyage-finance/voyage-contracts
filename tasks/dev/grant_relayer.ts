import { Voyage } from '@contracts';
import { task } from 'hardhat/config';

task('dev:grant-relayer', 'Sets trustedForwarder and voyagePaymaster')
  .addOptionalParam('relayer', 'The relayer address.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const {
      relayer = '0xBeb4B7a96DD4fc94767E6cc9E5ce881bc0Db2B5D'
    } = params;
    const voyage = await ethers.getContract<Voyage>('Voyage');

    // grant createVault
    var abi = ['function createVault(address,bytes20,uint256,uint256)'];
    var iface = new ethers.utils.Interface(abi);
    var selector = iface.getSighash('createVault');
    var tx = await voyage.grantPermission(relayer, voyage.address,selector);
    await tx.wait();
    console.log('granted createVaule: ', selector);

    // grant updateTwap
    var abi = ['function updateTwap(address,uint256)'];
    var iface = new ethers.utils.Interface(abi);
    var selector = iface.getSighash('updateTwap');
    var tx = await voyage.grantPermission(relayer, voyage.address,selector);
    await tx.wait();
    console.log('granted updateTwap: ', selector);
  });

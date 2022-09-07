import { ERC721 } from '@contracts';
import { task } from 'hardhat/config';

task('dev:nft-owner', 'Get owner of the given tokenId and contract')
  .addParam('tokenid', 'The tokenId')
  .addOptionalParam('collection', 'Address of the collection.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const mc = await ethers.getContract('Crab');
    const { tokenid, collection = mc.address } = params;
    const erc721 = await ethers.getContractAt<ERC721>('Crab', collection);
    const owner = await erc721.ownerOf(tokenid);
    console.log(`Owner of ${tokenid} is ${owner}`);
  });

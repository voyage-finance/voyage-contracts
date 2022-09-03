import { Voyage, WETH9 } from '@contracts';
import { providers } from 'ethers';
import { ethers, getNamedAccounts } from 'hardhat';
import { MAX_UINT_256 } from '../helpers/math';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage', owner);
  let vaultAddress = await voyage.getVault(owner);
  console.log('owner address: ', owner);
  console.log('vault address: ', vaultAddress);
  // const tx = {
  //   to: "0x9bb2eac903b1ff35825ebfece63758eeb49a731f",
  //   value: ethers.utils.parseEther('1'),
  // };
  // const signer = await ethers.getSigner(owner);
  // const createReceipt = await signer.sendTransaction(tx);
  // await createReceipt.wait();
  // console.log(`Transaction successful with hash: ${createReceipt.hash}`);

  const NFTContract = await ethers.getContractFactory('Crab');
  const nft = await NFTContract.attach(
    '0xd10E39Afe133eF729aE7f4266B26d173BC5AD1B1'
  );
  const nftOwner = await nft.ownerOf(1);
  console.log(nftOwner);
  var provider = providers.getDefaultProvider(providers.getNetwork('hardhat'));

  var transactionHash =
    '0x7fccda9a6e30489f8dc2d0ba72fb5326998487d1c6d9c5f45eb39fc486ad469c';
  const tran = await provider.getTransaction(transactionHash);
  console.log('transaction: ', tran);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

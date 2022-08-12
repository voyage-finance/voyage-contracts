import { expect } from 'chai';
import { ethers } from 'hardhat';
import { MockContextFacet } from 'typechain/MockContextFacet';
import { setupTestSuiteWithMocks } from '../helpers/setupTestSuite';

describe('Meta Transaction Receiver Context', function () {
  it('should return the original sender if tx is sent by trusted forwarder', async () => {
    const { owner, forwarder, voyage } = await setupTestSuiteWithMocks();
    const mockSecurityFacet = await ethers.getContractAt<MockContextFacet>(
      'MockContextFacet',
      voyage.address
    );
    const data = mockSecurityFacet.interface
      .encodeFunctionData('msgSender')
      .concat(owner.slice(2));
    const signer = await ethers.getSigner(forwarder);
    const tx = await signer.populateTransaction({
      to: voyage.address,
      data,
    });
    const pending = await signer.sendTransaction(tx);
    await expect(pending).to.emit(mockSecurityFacet, 'Sender').withArgs(owner);
  });

  it('should return the msg.sender if tx is not sent by trusted forwarder', async () => {
    const { owner, voyage } = await setupTestSuiteWithMocks();
    const mockSecurityFacet = await ethers.getContractAt<MockContextFacet>(
      'MockContextFacet',
      voyage.address
    );
    await expect(mockSecurityFacet.msgSender())
      .to.emit(mockSecurityFacet, 'Sender')
      .withArgs(owner);
  });

  it('should return correct msg data even if forwarded', async () => {
    const { owner, forwarder, voyage } = await setupTestSuiteWithMocks();
    const mockSecurityFacet = await ethers.getContractAt<MockContextFacet>(
      'MockContextFacet',
      voyage.address
    );
    const data = mockSecurityFacet.interface.encodeFunctionData('msgData', [
      '42',
      'meaning of life',
    ]);
    const signer = await ethers.getSigner(forwarder);
    const tx = await signer.populateTransaction({
      to: voyage.address,
      data: data.concat(owner.slice(2)),
    });
    const pending = await signer.sendTransaction(tx);
    await expect(pending)
      .to.emit(mockSecurityFacet, 'Data')
      .withArgs(data, '42', 'meaning of life');
  });
});

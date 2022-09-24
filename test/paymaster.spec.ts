import { WETH9 } from '@contracts';
import { BigNumber } from '@ethersproject/bignumber';
import { REFUND_GAS_UNITS } from '@helpers/constants';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { RelayRequest } from '@opengsn/common/dist/EIP712/RelayRequest';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

// TODO: this should be a mock IForwarder contract for integration tests.
// use a random 20-byte string for now
const relayWorker = ethers.Wallet.createRandom().address;
const signature = ethers.utils.randomBytes(65);
const validUntil = new Date().getTime().toString();

describe('VoyagePaymaster', function () {
  it('should only accept a trusted forwarder', async () => {
    const { owner, bob, paymaster, voyage } = await setupTestSuite();
    const relayRequest: RelayRequest = {
      request: {
        from: owner,
        to: voyage.address,
        gas: '888888',
        value: '0',
        nonce: '10',
        data: '0x',
        validUntil,
      },
      relayData: {
        gasPrice: ethers.utils.parseUnits('32', 'gwei').toString(),
        pctRelayFee: '0',
        baseRelayFee: '0',
        paymaster: paymaster.address,
        paymasterData: '0x',
        relayWorker,
        forwarder: bob,
        clientId: '8',
      },
    };

    await expect(
      paymaster.preRelayedCall(
        relayRequest,
        signature,
        '0x',
        ethers.BigNumber.from(1000000)
      )
    ).to.be.revertedWith('Forwarder is not trusted');
  });

  it('should reject transaction if the sender does not have a vault', async () => {
    const { alice, forwarder, paymaster, voyage } = await setupTestSuite();
    const relayRequest: RelayRequest = {
      request: {
        from: alice,
        to: voyage.address,
        gas: '888888',
        value: '0',
        nonce: '10',
        data: '0x',
        validUntil,
      },
      relayData: {
        gasPrice: ethers.utils.parseUnits('32', 'gwei').toString(),
        pctRelayFee: '0',
        baseRelayFee: '0',
        paymaster: paymaster.address,
        paymasterData: '0x',
        relayWorker,
        forwarder,
        clientId: '8',
      },
    };
    await expect(
      paymaster.preRelayedCall(
        relayRequest,
        signature,
        '0x',
        ethers.BigNumber.from(1_000_000)
      )
    ).to.be.revertedWithCustomError(paymaster, 'SenderNoVault');
  });

  it('should accept the transaction if the sender has a vault', async () => {
    const { owner, forwarder, paymaster, voyage } = await setupTestSuite();
    const relayRequest: RelayRequest = {
      request: {
        from: owner,
        to: voyage.address,
        gas: '888888',
        value: '0',
        nonce: '10',
        data: '0x',
        validUntil,
      },
      relayData: {
        gasPrice: ethers.utils.parseUnits('32', 'gwei').toString(),
        pctRelayFee: '0',
        baseRelayFee: '0',
        paymaster: paymaster.address,
        paymasterData: '0x',
        relayWorker,
        forwarder,
        clientId: '8',
      },
    };
    await paymaster.preRelayedCall(
      relayRequest,
      signature,
      '0x',
      ethers.BigNumber.from(1_000_000)
    );
    await expect(
      paymaster.preRelayedCall(
        relayRequest,
        signature,
        '0x',
        ethers.BigNumber.from(1_000_000)
      )
    ).not.to.be.reverted;
  });

  it('should not accept transactions if the vault has insufficient balance', async () => {
    const { alice, forwarder, paymaster, voyage } = await setupTestSuite();
    // vault has no ETH or WETH balance.
    await voyage.createVault(
      alice,
      ethers.utils
        .keccak256(ethers.utils.toUtf8Bytes('alice@wonder.land'))
        .slice(0, 42),
      REFUND_GAS_UNITS
    );
    const relayRequest: RelayRequest = {
      request: {
        from: alice,
        to: voyage.address,
        gas: '888888',
        value: '0',
        nonce: '10',
        data: '0x',
        validUntil,
      },
      relayData: {
        gasPrice: ethers.utils.parseUnits('32', 'gwei').toString(),
        pctRelayFee: '0',
        baseRelayFee: '0',
        paymaster: paymaster.address,
        paymasterData: '0x',
        relayWorker,
        forwarder,
        clientId: '8',
      },
    };
    await expect(
      paymaster.preRelayedCall(
        relayRequest,
        signature,
        '0x',
        ethers.BigNumber.from(1_000_000_000)
      )
    ).to.be.revertedWithCustomError(paymaster, 'VaultBalanceInsufficient');
  });

  it('should accept transactions if the vault has sufficient balance', async () => {
    const { alice, forwarder, paymaster, voyage } = await setupTestSuite();
    // vault has no ETH or WETH balance.
    await voyage.createVault(
      alice,
      ethers.utils
        .keccak256(ethers.utils.toUtf8Bytes('alice@wonder.land'))
        .slice(0, 42),
      REFUND_GAS_UNITS
    );
    const deployedVault = await voyage.getVaultAddr(alice);
    // send her Vault some $
    const weth9 = await ethers.getContract<WETH9>('WETH9');
    const signer = await ethers.getSigner(alice);
    await signer.sendTransaction({
      to: deployedVault,
      value: ethers.BigNumber.from('100000000000000000'),
    });
    await weth9.deposit({
      value: ethers.BigNumber.from('100000000000000000'),
    });
    await weth9.transfer(
      deployedVault,
      ethers.BigNumber.from('100000000000000000')
    );
    const relayRequest: RelayRequest = {
      request: {
        from: alice,
        to: voyage.address,
        gas: '888888',
        value: '0',
        nonce: '10',
        data: '0x',
        validUntil,
      },
      relayData: {
        gasPrice: ethers.utils.parseUnits('32', 'gwei').toString(),
        pctRelayFee: '0',
        baseRelayFee: '0',
        paymaster: paymaster.address,
        paymasterData: '0x',
        relayWorker,
        forwarder,
        clientId: '8',
      },
    };
    await expect(
      paymaster.preRelayedCall(
        relayRequest,
        signature,
        '0x',
        ethers.BigNumber.from(1_000_000)
      )
    ).not.to.be.reverted;
  });

  it('should return correct gas and data limits', async () => {
    const { paymaster } = await setupTestSuite();
    const relayHubOverhead = await paymaster.FORWARDER_HUB_OVERHEAD();
    const expectedPreRelayedCallGasLimit =
      await paymaster.PRE_RELAYED_CALL_OVERHEAD();
    const expectedPostRelayedCallGasLimit =
      await paymaster.POST_RELAYED_CALL_OVERHEAD();
    const expectedCallDataSizeLimit = await paymaster.CALLDATA_LIMIT();
    const {
      acceptanceBudget,
      preRelayedCallGasLimit,
      postRelayedCallGasLimit,
      calldataSizeLimit,
    } = await paymaster.getGasAndDataLimits();
    expect(acceptanceBudget).to.be.equal(
      ethers.BigNumber.from(60000).add(relayHubOverhead)
    );
    expect(preRelayedCallGasLimit).to.be.equal(expectedPreRelayedCallGasLimit);
    expect(postRelayedCallGasLimit).to.be.equal(
      expectedPostRelayedCallGasLimit
    );
    expect(calldataSizeLimit).to.be.equal(expectedCallDataSizeLimit);
  });
});

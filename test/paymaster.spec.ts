import { BigNumber } from '@ethersproject/bignumber';
import { RelayRequest } from '@opengsn/common/dist/EIP712/RelayRequest';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Vault } from 'typechain/Vault';
import { WETH9 } from 'typechain/WETH9';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';

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
        .slice(0, 42)
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
        .slice(0, 42)
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

  it('postRelayedCalled should get a refund from the Vault', async () => {
    const { alice, forwarder, paymaster, treasury, voyage } =
      await setupTestSuite();
    // vault has no ETH or WETH balance.
    await voyage.createVault(
      alice,
      ethers.utils
        .keccak256(ethers.utils.toUtf8Bytes('alice@wonder.land'))
        .slice(0, 42)
    );
    const deployedVault = await voyage.getVaultAddr(alice);
    // send her Vault some $
    const ETH_TO_DEPOSIT = ethers.utils.parseEther('10000');
    const weth9 = await ethers.getContract<WETH9>('WETH9');
    const signer = await ethers.getSigner(alice);
    await signer.sendTransaction({
      to: deployedVault,
      value: ETH_TO_DEPOSIT,
    });
    await weth9.deposit({
      value: ETH_TO_DEPOSIT,
    });
    await weth9.transfer(deployedVault, ETH_TO_DEPOSIT);
    const initialVaultBalance = await ethers.provider.getBalance(deployedVault);
    const initialTreasuryBalance = await ethers.provider.getBalance(treasury);
    const gasPrice = ethers.utils.parseUnits('32', 'gwei');
    const gasUseWithoutPost = ethers.BigNumber.from(1_000_000);
    const vault = await ethers.getContractAt<Vault>(
      'hardhat-diamond-abi/HardhatDiamondABI.sol:Vault',
      deployedVault
    );
    const tx = await paymaster.postRelayedCall(
      ethers.utils.defaultAbiCoder.encode(['address'], [deployedVault]),
      true,
      gasUseWithoutPost,
      {
        gasPrice: gasPrice.toString(),
        pctRelayFee: '0',
        baseRelayFee: '0',
        paymaster: paymaster.address,
        paymasterData: '0x',
        relayWorker,
        forwarder,
        clientId: '8',
      }
    );

    await expect(tx)
      .to.emit(vault, 'GasRefunded')
      .withArgs(
        paymaster.address,
        treasury,
        anyValue,
        ethers.constants.Zero,
        '0x'
      );
    const finalVaultBalance = await ethers.provider.getBalance(deployedVault);
    const finalTreasuryBalance = await ethers.provider.getBalance(treasury);
    const gasRefunded = initialVaultBalance.sub(finalVaultBalance);
    expect(finalTreasuryBalance.sub(initialTreasuryBalance)).to.be.equal(
      gasRefunded
    );
  });

  it('should unwrap WETH and refund', async () => {
    const { alice, forwarder, paymaster, treasury, voyage } =
      await setupTestSuite();
    // vault has no ETH or WETH balance.
    await voyage.createVault(
      alice,
      ethers.utils
        .keccak256(ethers.utils.toUtf8Bytes('alice@wonder.land'))
        .slice(0, 42)
    );
    const deployedVault = await voyage.getVaultAddr(alice);
    // send her Vault some $, but not enough to cover gas fees
    const ETH_TO_DEPOSIT = ethers.utils.parseEther('0.01');
    const WETH_TO_DEPOSIT = ethers.utils.parseEther('100');
    const weth9 = await ethers.getContract<WETH9>('WETH9');
    const signer = await ethers.getSigner(alice);
    await signer.sendTransaction({
      to: deployedVault,
      value: ETH_TO_DEPOSIT,
    });
    await weth9.deposit({
      value: WETH_TO_DEPOSIT,
    });
    await weth9.transfer(deployedVault, WETH_TO_DEPOSIT);
    const initialVaultEthBalance = await ethers.provider.getBalance(
      deployedVault
    );
    const initialVaultWethBalance = await weth9.balanceOf(deployedVault);
    const initialVaultBalance = initialVaultEthBalance.add(
      initialVaultWethBalance
    );
    const initialTreasuryBalance = await ethers.provider.getBalance(treasury);
    const postOverhead = await paymaster.REFUND_GAS_OVERHEAD();
    const gasPrice = ethers.utils.parseUnits('32', 'gwei');
    const gasUseWithoutPost = ethers.BigNumber.from(1_000_000);
    const expectedRefund = gasUseWithoutPost
      .add(postOverhead)
      .add(ethers.BigNumber.from(24000))
      .mul(gasPrice);
    const vault = await ethers.getContractAt<Vault>(
      'hardhat-diamond-abi/HardhatDiamondABI.sol:Vault',
      deployedVault
    );
    const tx = await paymaster.postRelayedCall(
      ethers.utils.defaultAbiCoder.encode(['address'], [deployedVault]),
      true,
      gasUseWithoutPost,
      {
        gasPrice: gasPrice.toString(),
        pctRelayFee: '0',
        baseRelayFee: '0',
        paymaster: paymaster.address,
        paymasterData: '0x',
        relayWorker,
        forwarder,
        clientId: '8',
      }
    );

    await expect(tx)
      .to.emit(vault, 'GasRefunded')
      .withArgs(
        paymaster.address,
        treasury,
        (refund: BigNumber) => refund.gte(expectedRefund),
        ethers.constants.Zero,
        '0x'
      );
    const finalVaultEthBalance = await ethers.provider.getBalance(
      deployedVault
    );
    const finalVaultWethBalance = await weth9.balanceOf(deployedVault);
    const finalVaultBalance = finalVaultEthBalance.add(finalVaultWethBalance);
    const finalTreasuryBalance = await ethers.provider.getBalance(treasury);
    const gasRefunded = initialVaultBalance.sub(finalVaultBalance);
    expect(finalTreasuryBalance.sub(initialTreasuryBalance)).to.be.equal(
      gasRefunded
    );
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

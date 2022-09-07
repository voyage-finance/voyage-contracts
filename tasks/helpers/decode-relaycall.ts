import { RelayRequest } from '@opengsn/common/dist/EIP712/RelayRequest';
import { abi } from 'artifacts/@opengsn/contracts/src/RelayHub.sol/RelayHub.json';
import { task } from 'hardhat/config';

task('dev:parse-tx', 'Decodes calldata for RelayHub::relayCall')
  .addParam('calldata', 'The serialized tx data.')
  .setAction(async (params, hre) => {
    const { ethers } = hre;
    const { calldata } = params;
    const relayHub = new ethers.Contract(ethers.constants.AddressZero, abi);
    const {
      maxAcceptanceBudget,
      relayRequest,
      signature,
      approvalData,
      externalGasLimit,
    } = relayHub.interface.decodeFunctionData('relayCall', calldata);
    const { request, relayData } = relayRequest as RelayRequest;
    const { from, to, value, gas, nonce, data, validUntil } = request;
    const {
      gasPrice,
      pctRelayFee,
      baseRelayFee,
      relayWorker,
      paymaster,
      paymasterData,
      clientId,
      forwarder,
    } = relayData;
    console.log(
      JSON.stringify(
        {
          maxAcceptanceBudget: maxAcceptanceBudget.toString(),
          relayRequest: {
            request: {
              from,
              to,
              data,
              value: value.toString(),
              nonce: nonce.toString(),
              gas: gas.toString(),
              validUntil: validUntil.toString(),
            },
            relayData: {
              gasPrice: gasPrice.toString(),
              pctRelayFee: pctRelayFee.toString(),
              baseRelayFee: baseRelayFee.toString(),
              relayWorker,
              paymaster,
              paymasterData,
              clientId: clientId.toString(),
              forwarder,
            },
          },
          signature,
          approvalData,
          externalGasLimit: externalGasLimit.toString(),
        },
        null,
        4
      )
    );
  });

const balance = '1000000000000000000000000';

const accounts: [{ secretKey: string; balance: string }] = [
  {
    secretKey:
      '0xc5e8f61d1ab959b397eecc0a37a6517b8e67a0e7cf1f4bce5591f3ed80199122',
    balance,
  },
];

export const getTestWallets = (): [{ secretKey: string; balance: string }] => {
  if (!accounts.every((element) => element.secretKey))
    throw new Error('INVALID_TEST_WALLETS');
  return accounts;
};

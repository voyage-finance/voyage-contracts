import { SignerWithAddress, TestEnv } from './make-suite';
import { approve, borrow, deposit, margin, withdraw } from './actions';

export interface Action {
  name: string;
  args?: any;
  expected: string;
  revertMessage?: string;
}

export interface Story {
  description: string;
  actions: Action[];
}

export const executeStory = async (story: Story, testEnv: TestEnv) => {
  for (const action of story.actions) {
    const { users } = testEnv;
    await executeAction(action, users, testEnv);
  }
};

const executeAction = async (
  action: Action,
  users: SignerWithAddress[],
  testEnv: TestEnv
) => {
  const { reserve, user: userIndex } = action.args;
  const { name, expected, revertMessage } = action;

  if (!name || name === '') {
    throw 'Action name is missing';
  }
  if (!reserve || reserve === '') {
    throw 'Invalid reserve selected for deposit';
  }
  if (!userIndex || userIndex === '') {
    throw `Invalid user selected to deposit into the ${reserve} reserve`;
  }

  if (!expected || expected === '') {
    throw `An expected resut for action ${name} is required`;
  }

  const user = users[parseInt(userIndex)];

  //const userPrivateKey = getTestWallets()[parseInt(userIndex) + 1].secretKey;

  switch (name) {
    case 'deposit':
      const { reserve, tranche, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${reserve} reserve`;
      }
      await deposit(reserve, tranche, amount, testEnv);
      break;
    case 'withdraw': {
      const { reserve, tranche, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${reserve} reserve`;
      }
      await withdraw(reserve, tranche, amount, testEnv);
      break;
    }
    case 'borrow': {
      const { reserve, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${reserve} reserve`;
      }
      await borrow(reserve, amount, testEnv);
      break;
    }
    case 'margin': {
      const { reserve, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${reserve} reserve`;
      }
      await margin(reserve, amount, testEnv);
    }
    case 'approve': {
      const { reserve, tranche, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${reserve} reserve`;
      }
      await approve(tranche, amount, testEnv);
      break;
    }

    default:
      throw `Invalid action requested: ${name}`;
  }
};

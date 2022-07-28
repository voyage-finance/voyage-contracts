import { SignerWithAddress, TestEnv } from './make-suite';
import { approve, borrow, deposit, margin, repay, withdraw } from './actions';

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
  const { cname, user: userIndex } = action.args;
  const { name, expected, revertMessage } = action;

  if (!name || name === '') {
    throw 'Action name is missing';
  }
  if (!cname || cname === '') {
    throw 'Invalid collection selected for deposit';
  }
  if (!userIndex || userIndex === '') {
    throw `Invalid user selected to deposit into the ${cname} collection`;
  }

  if (!expected || expected === '') {
    throw `An expected resut for action ${name} is required`;
  }

  const user = users[parseInt(userIndex)];

  //const userPrivateKey = getTestWallets()[parseInt(userIndex) + 1].secretKey;

  switch (name) {
    case 'deposit':
      console.log('case deposit');
      const { cname, tranche, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${cname} collection`;
      }
      console.log('before deposit');
      await deposit(cname, tranche, amount, testEnv);
      console.log('after deposit');
      break;
    case 'withdraw': {
      const { cname, tranche, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${cname} collection`;
      }
      await withdraw(cname, tranche, amount, testEnv);
      break;
    }
    case 'borrow': {
      const { cname, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${cname} collection`;
      }
      await borrow(cname, amount, testEnv);
      break;
    }
    case 'margin': {
      const { cname, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${cname} collection`;
      }
      await margin(cname, amount, testEnv);
    }
    case 'approve': {
      const { cname, tranche, amount } = action.args;
      if (!amount || amount === '') {
        throw `Invalid amount to deposit into the ${cname} collection`;
      }
      await approve(tranche, amount, testEnv);
      break;
    }
    case 'repay': {
      const { cname, loan } = action.args;
      await repay(cname, loan, testEnv);
      break;
    }

    default:
      throw `Invalid action requested: ${name}`;
  }
};

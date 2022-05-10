const { grantAllowance } = require('../helpers/contract');

async function main() {
  await grantAllowance();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

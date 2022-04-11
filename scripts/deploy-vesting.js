const hre = require('hardhat');

async function main() {
  let _token = '';

  const VestingContract = await hre.ethers.getContractFactory('Vesting');
  const vesting = await VestingContract.deploy(_token);

  await vesting.deployed();

  console.log('Vesting contract deployed Address:', token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

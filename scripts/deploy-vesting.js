const hre = require('hardhat');

async function main() {
  let _token = '0x5FbDB2315678afecb367f032d93F642f64180aa3';

  const VestingContract = await hre.ethers.getContractFactory('Vesting');
  const vesting = await VestingContract.deploy(_token);

  await vesting.deployed();

  console.log('Vesting contract deployed Address:', vesting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

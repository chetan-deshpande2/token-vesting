const hre = require('hardhat');

async function main() {
  let _token = '0x8ACfC506c55aF33dC844b0F845222616d9FfB119';

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

const hre = require('hardhat');

async function main() {
  let _token = '0x7F1d3d3E519b52ECEe287c7aCa5D594908BFaC8a';

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

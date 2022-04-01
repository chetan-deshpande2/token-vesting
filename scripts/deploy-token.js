const hre = require('hardhat');

async function main() {
  let initialSupply = 1000;
  const name = 'Vesting Token';
  const symbol = 'VST';
  const Token = await hre.ethers.getContractFactory('Token');
  const token = await Token.deploy(name, symbol, initialSupply);

  await greeter.deployed();

  console.log('Greeter deployed to:', greeter.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

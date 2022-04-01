const hre = require('hardhat');

async function main() {
  let initialSupply = 1000;
  const name = 'Vesting Token';
  const symbol = 'VST';
  const Token = await hre.ethers.getContractFactory('Token');
  const token = await Token.deploy(name, symbol, initialSupply);

  await token.deployed();

  console.log('Token deployed to address :', token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

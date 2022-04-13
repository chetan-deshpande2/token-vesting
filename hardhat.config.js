require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-etherscan');
require('dotenv').config();

task('accounts', 'Prints the list of accounts', async (hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.2'
      }
    ]
  },
  networks: {
    rinkeby: {
      url: process.env.RINKEBY_RPC_URL,
      accounts: [
        process.env.RINKEBY_PRIVATE_KEY_ACCOUNT1,
        process.env.RINKEBY_PRIVATE_KEY_ACCOUNT3
      ],
      gasPrice: 3000000000
    },
    goerli: {
      url: process.env.RINKEBY_RPC_URL,
      accounts: [
        process.env.RINKEBY_PRIVATE_KEY_ACCOUNT1,
        process.env.RINKEBY_PRIVATE_KEY_ACCOUNT3
      ],
      gasPrice: 3000000000
    }
  },

  etherscan: {
    apiKey: process.env.API_KEY
  }
};
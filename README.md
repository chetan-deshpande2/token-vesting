

# Linear Vesting Smart Contract

Token Vesting contract can release its token balance gradually like a typical vesting scheme, with a cliff and vesting period. Optionally revocable by the owner.

# Features 
1. 3 Roles (Advisor, Partnerships, Mentors)
2. Dynamic TGE (Token Generation Event) for every role. % of Tokens to be released right after vesting
3. There should be a cliff of some duration added by the admin. No releasing of tokens for a few weeks or a few months.
4. The Vesting should be a linear vesting approach which means it should release some amounts of tokens every day to be claimed by users based upon the allocations decided by the admin.

# 

## Deployment

To deploy this project run

```bash
 npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/deploy-vesting
npx hardhat help
```


## Rinkeby  Testnet Deployed Address

Vesing Contract Address : 0x2ac898B93B28aA8bB50a7A9100d26Ffb8965B691

Token Address : 0x5FbDB2315678afecb367f032d93F642f64180aa3


### 🌡️ Testing

```console
$ yarn test
```

### 📊 Code coverage

```console
$ yarn coverage
```

The report will be printed in the console and a static website containing full report will be generated in `coverage` directory.

### ✨ Code style

```console
$ yarn prettier
```

### 🐱‍💻 Verify & Publish contract source code

```console
$ npx hardhat  verify --network mainnet $CONTRACT_ADDRESS $CONSTRUCTOR_ARGUMENTS





## 🔗 Contract  Links

Token Contract : https://rinkeby.etherscan.io/address/0x5FbDB2315678afecb367f032d93F642f64180aa3

Vesting Contract : https://rinkeby.etherscan.io/address/0x2ac898B93B28aA8bB50a7A9100d26Ffb8965B691


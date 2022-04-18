

# Linear Vesting Smart Contract

Token Vesting contract can release its token balance gradually like a typical vesting scheme, with a cliff and vesting period. Optionally revocable by the owner.

# Features 
1. 3 Roles (Advisor, Partnerships, Mentors)
2. Dynamic TGE (Token Generation Event) for every role. % of Tokens to be released right after vesting
3. There should be a cliff of some duration added by the admin. No releasing of tokens for a few weeks or a few months.
4. The Vesting should be a linear vesting approach which means it should release some amounts of tokens every day to be claimed by users based upon the allocations decided by the admin.

# 

## Deployment

To deploy this project      run

```bash
 npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/deploy-vesting
npx hardhat help
```


## Goerli  Testnet Deployed Address

Vesting Contract Address :  0xb3037A51B3d966697A42459afb4F2d1BCDb4251B

Token Address : 0x5DCaA0fd7EE70F5098e084d5397F416816E01cECg


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

Token Contract :https://goerli.etherscan.io/token/0x5DCaA0fd7EE70F5098e084d5397F416816E01cEC
Vesting Contract :https://goerli.etherscan.io/address/0xb3037A51B3d966697A42459afb4F2d1BCDb4251B#code
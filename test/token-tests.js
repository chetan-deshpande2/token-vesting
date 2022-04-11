const { expect } = require('chai');

describe('Token contract', function () {
  let Token;
  let token;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    Token = await ethers.getContractFactory('Token');
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    token = await Token.deploy();
  });

  describe('Deployment', function () {
    it('Should assign the total supply of tokens to the owner', async function () {
      const ownerBalance = await token.balanceOf(owner.address);
      expect(await token.totalSupply()).to.equal(ownerBalance);
    });
  });


  describe('Token Properties', () => {
    it('Should have a name', async function () {
      expect(await token.name()).to.equal('Vesting Token');
    });
    it('Should have a symbol', async function () {
      expect(await token.symbol()).to.equal('VST');
    });
  });

  describe('Transactions', function () {
    it('Should transfer tokens between accounts', async function () {
      // Transfer 50 tokens from owner to addr1
      await token.transfer(addr1.address, 50);
      const addr1Balance = await token.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(50);

      // Transfer 50 tokens from addr1 to addr2
      // We use .connect(signer) to send a transaction from another account
      await token.connect(addr1).transfer(addr2.address, 50);
      const addr2Balance = await token.balanceOf(addr2.address);
      expect(addr2Balance).to.equal(50);
    });

    it('Should fail if sender doesn’t have enough tokens', async function () {
      const initialOwnerBalance = await token.balanceOf(owner.address);

      // Try to send 1 token from addr1 (0 tokens) to owner (1000000 tokens).
      // `require` will evaluate false and revert the transaction.
      await expect(
        token.connect(addr1).transfer(owner.address, 1)
      ).to.be.revertedWith('Not enough tokens');

      // Owner balance shouldn't have changed.
      expect(await token.balanceOf(owner.address)).to.equal(
        initialOwnerBalance
      );
    });
  });
});

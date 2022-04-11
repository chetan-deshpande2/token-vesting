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


});

const { expect } = require("chai");

describe("Token Vestings", () => {
  let Token;
  let testToken;
  let TokenVesting;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  before(async () => {
    Token = await ethers.getContractFactory("Token");
    TokenVesting = await ethers.getContractFactory("MockTokenVesting");
  });
  beforeEach(async () => {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    testToken = await Token.deploy();
    await testToken.deployed();
  });

  describe("Vesting", () => {
    it("Should assign the total supply of tokens to the owner", async () => {
      const ownerBalance = await testToken.balanceOf(owner.address);
      expect(await testToken.totalSupply()).to.equal(ownerBalance);
    });
  });
  it("should vest Token Gradually-Advisors ", async () => {
    const tokenVesting = await TokenVesting.deploy(testToken.address);
    await tokenVesting.deployed();
    expect((await tokenVesting.getToken()).toString()).to.equal(
      testToken.address
    );
    // send tokens to vesting contract
    await expect(testToken.transfer(tokenVesting.address, 10000))
      .to.emit(testToken, "Transfer")
      .withArgs(owner.address, tokenVesting.address, 10000);
    const vestingContractBalance = await testToken.balanceOf(
      tokenVesting.address
    );
    expect(vestingContractBalance).to.equal(10000);

    const role = 1;
    const baseTime = 1649677618;
    const beneficiary = addr1.address;
    const startTime = baseTime;
    const cliff = 120;
    const duration = 300;
    const slicePeriodSeconds = 12;
    const revokable = true;
    const amount = 10000;
    // create vesting schedule
    await tokenVesting.createVestingSchedule(
      role,
      beneficiary.address,
      startTime,
      cliff,
      duration,
      slicePeriodSeconds,
      revokable,
      amount
    );
    expect(await tokenVesting.getVestingSchedule(role)).to.equal(1);
    const vestingScheduleId =
      await tokenVesting.computeVestingScheduleIdForAddressAndIndex(
        beneficiary.address,
        1
      );
    expect(
      await tokenVesting.computeReleasableAmount(vestingScheduleId, 1)
    ).to.be.equal(200);
    // set time to half the vesting period
    const halfTime = baseTime + 60;
    await tokenVesting.setCurrentTime(halfTime);
    expect(
      await tokenVesting
        .connect(beneficiary)
        .computeReleasableAmount(vestingScheduleId, role)
    ).to.equal(2160);
    let interval = afterCliff + 36;
    expect(
      await tokenVesting
        .connect(beneficiary)
        .computeReleasableAmount(vestingScheduleId, r)
    ).to.be.equal(10000);
    await expect(
      tokenVesting.connect(beneficiary).release(vestingScheduleId, 1000, r)
    )
      .to.emit(testToken, "Transfer")
      .withArgs(tokenVesting.address, beneficiary.address, 1000);
      
  });
  
});

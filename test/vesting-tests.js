/* eslint-disable no-undef */
const { expect } = require("chai");
const { ethers } = require("hardhat");

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
    [owner, addr1, addr2, ...addr] = await ethers.getSigners();

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
    await expect(testToken.transfer(tokenVesting.address, 100000000))
      .to.emit(testToken, "Transfer")
      .withArgs(owner.address, tokenVesting.address, 100000000);
    const vestingContractBalance = await testToken.balanceOf(
      tokenVesting.address
    );
    expect(vestingContractBalance).to.equal(100000000);

    await tokenVesting.setTEG(5, 0, 7);
    let tegForAdvisor = await tokenVesting.advisersTGEPool();
    tegForPartner = teg.toString();
    expect(tegForPartner).to.equal("5");
    await tokenVesting.calculatePools();
    let tegBank = await tokenVesting.advisorsTEGBank();
    tegBank = tegBank.toString();
    expect(tegBank).to.equal("700000");
    let totalAmount = await tokenVesting.totalAmountForAdvisors();
    totalAmount = totalAmount.toString();
    expect(totalAmount).to.equal("9300000");
    let withdrawAmount = await tokenVesting.getWithdrawableAmount();
    withdrawAmount = withdrawAmount.toString();
    expect(withdrawAmount).to.equal("8000000");

    let tegForPartner = await tokenVesting.partnersTGEPool();
    tegForPartner = tegForPartner.toString();
    expect(tegForPartner).to.equal("0");
    let tegBankForPartner = await tokenVesting.partnersTEGBank();
    tegBankForPartner = tegBankForPartner.toString();
    expect(tegBankForPartner).to.equal("0");
    let totalAmountForPartner = await tokenVesting.totalAmountForPartners();
    totalAmountForPartner = totalAmountForPartner.toString();
    expect(totalAmountForPartner).to.equal("400000");

    let tegForMentor = await tokenVesting.mentorsTGEPool();
    tegForMentor = tegForMentor.toString();
    expect(tegForMentor).to.equal("7");
    let tegBankForMentor = await tokenVesting.mentorsTEGBank();
    tegBankForMentor = tegBankForMentor.toString();
    expect(tegBankForMentor).to.equal("9300000");
    let totalAmountForMentor = await tokenVesting.totalAmountForMentors();
    totalAmountForMentor = totalAmountForMentor.toString();
    expect(totalAmountForMentor).to.equal("5700000");

    const role = 0;
    const baseTime = 1649831209;
    const beneficiary = addr1.address;
    const startTime = baseTime;
    const cliff = 60;
    const duration = 1000;
    const slicePeriodSeconds = 1;
    const revokable = true;
    const amount = 100;

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
    expect(await tokenVesting.getVestingSchedulesCount()).to.equal(1);
    expect(
      await tokenVesting.getVestingSchedulesCountByBeneficiary(
        beneficiary.address
      )
    ).to.equal(1);
    const vestingScheduleId = await tokenVesting.getVestingIdAtIndex(0);

    //!check that vested amount is 0
    expect(
      await tokenVesting.computeReleasableAmount(vestingScheduleId, 0)
    ).to.be.equal(0);

    const halfTime = baseTime + duration / 2;
    await tokenVesting.setCurrentTime(halfTime);
    expect(
      await tokenVesting
        .connect(beneficiary)
        .computeReleasableAmount(vestingScheduleId, halfTime)
    ).to.be.equal(50);
    await expect(
      tokenVesting.connect(addr2).release(vestingScheduleId, 100, role)
    ).to.be.revertedWith(
      "TokenVesting: only beneficiary and owner can release vested tokens"
    );
    await expect(
      tokenVesting.connect(beneficiary).release(vestingScheduleId, 100, role)
    ).to.be.revertedWith(
      "TokenVesting: cannot release tokens, not enough vested tokens"
    );
    await expect(
      tokenVesting.connect(beneficiary).release(vestingScheduleId, 10, role)
    )
      .to.emit(testToken, "Transfer")
      .withArgs(tokenVesting.address, beneficiary.address, 10);
    expect(
      await tokenVesting
        .connect(beneficiary)
        .computeReleasableAmount(vestingScheduleId, role)
    ).to.be.equal(40);
    expect(tokenVesting.released).to.be.equal(10);
    await tokenVesting.setCurrentTime(baseTime + duration + 1);

  });
  it('should release vested tokens if revoked', async function() {})
});

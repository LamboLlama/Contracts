import { expect } from "chai";
import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Vesting, ERC20Mock } from "@ethers-v5";
import { Reverter } from "@/test/helpers/reverter";

describe("Vesting", function () {
  let vesting: Vesting;
  let token: ERC20Mock;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr3: SignerWithAddress;
  const reverter = new Reverter();

  beforeEach(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("ERC20Mock");
    token = (await Token.deploy("Mock Token", "MTK")) as ERC20Mock;
    await token.deployed();

    const Vesting = await ethers.getContractFactory("Vesting");
    vesting = (await Vesting.deploy(token.address)) as Vesting;
    await vesting.deployed();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("Deployment", function () {
    it("Should set the correct token address", async () => {
      expect(await vesting.token()).to.equal(token.address);
    });

    it("Should not allow zero address for token", async () => {
      const Vesting = await ethers.getContractFactory("Vesting");
      await expect(Vesting.deploy(ethers.constants.AddressZero)).to.be.revertedWith("Vesting: zero token address");
    });
  });

  describe("withdraw", async () => {
    it("Should allow owner to withdraw tokens before contract is fixed", async function () {
      await token.mint(vesting.address, 1000);
      await vesting.withdraw();
      expect(await token.balanceOf(owner.address)).to.equal(1000);
    });

    it("Should not allow non-owner to withdraw when the contract is not fixed", async () => {
      await token.mint(vesting.address, 1000);
      await expect(vesting.connect(addr1).withdraw()).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should not allow owner to withdraw tokens after contract is fixed", async function () {
      await token.mint(vesting.address, 1000);
      await vesting.fix();
      await expect(vesting.withdraw()).to.be.revertedWith("Vesting: not available after the contract is fixed");
    });
  });

  describe("fix", async () => {
    it("Should allow owner to fix the contract", async function () {
      await vesting.fix();
      expect(await vesting.configuratedAndFixed()).to.equal(true);
    });

    it("Should not allow non-owner to fix the contract", async function () {
      await expect(vesting.connect(addr1).fix()).to.be.revertedWith("Ownable: caller is not the owner");
      expect(await vesting.configuratedAndFixed()).to.equal(false);
    });
  });

  describe("Set Vesting Schedule", function () {
    it("Should allow owner to set vesting schedule", async () => {
      const start_ = (await time.latest()) + 1000;
      const duration_ = 10000;
      await vesting.setVestingSchedule(addr1.address, 100, start_, duration_);
      const schedule = await vesting.vestingSchedules(addr1.address);
      expect(schedule.totalAmount).to.equal(100);
      expect(schedule.start).to.equal(start_);
      expect(schedule.duration).to.equal(duration_);
    });

    it("Should not allow non-owner to set vesting schedule", async () => {
      const start_ = (await time.latest()) + 1000;
      const duration_ = 10000;
      await expect(vesting.connect(addr1).setVestingSchedule(addr1.address, 100, start_, duration_)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("Should not allow setting zero address for beneficiary", async () => {
      const start_ = (await time.latest()) + 1000;
      const duration_ = 10000;
      await expect(vesting.setVestingSchedule(ethers.constants.AddressZero, 100, start_, duration_)).to.be.revertedWith(
        "Vesting: zero beneficiary address"
      );
    });

    it("Should not allow setting zero total amount", async () => {
      const start_ = (await time.latest()) + 1000;
      const duration_ = 10000;
      await expect(vesting.setVestingSchedule(addr1.address, 0, start_, duration_)).to.be.revertedWith(
        "Vesting: zero total amount"
      );
    });

    it("Should not allow setting zero duration", async () => {
      const start_ = (await time.latest()) + 1000;
      await expect(vesting.setVestingSchedule(addr1.address, 100, start_, 0)).to.be.revertedWith(
        "Vesting: zero duration"
      );
    });

    it("Should not allow setting vesting schedule after contract is fixed", async function () {
      const start_ = (await time.latest()) + 1000;
      const duration_ = 10000;

      await vesting.fix();

      await expect(vesting.setVestingSchedule(addr1.address, 100, start_, duration_)).to.be.revertedWith(
        "Vesting: not available after the contract is fixed"
      );
    });
  });

  describe("Claim Tokens", function () {
    beforeEach(async () => {
      await token.mint(vesting.address, 1000);
      const start_ = (await time.latest()) + 1000;
      const duration_ = 10000;
      await vesting.setVestingSchedule(addr1.address, 100, start_, duration_);
      await vesting.setVestingSchedule(addr2.address, 200, start_, duration_);
    });

    it("Should allow beneficiaries to claim vested tokens after start period", async () => {
      const start_ = (await vesting.vestingSchedules(addr1.address)).start;
      await time.setNextBlockTimestamp(start_.add(5000));

      await vesting.connect(addr1).claimTokens();
      expect(await token.balanceOf(addr1.address)).to.equal(50);

      await vesting.connect(addr2).claimTokens();
      expect(await token.balanceOf(addr2.address)).to.equal(100);
    });

    it("Should allow beneficiaries to claim vested tokens after start period close to the end", async () => {
      const start_ = (await vesting.vestingSchedules(addr1.address)).start;
      await time.setNextBlockTimestamp(start_.add(9500));

      await vesting.connect(addr1).claimTokens();
      expect(await token.balanceOf(addr1.address)).to.equal(95);

      await vesting.connect(addr2).claimTokens();
      expect(await token.balanceOf(addr2.address)).to.equal(190);
    });

    it("Should allow beneficiaries to claim all vested tokens after full duration", async () => {
      const start_ = (await vesting.vestingSchedules(addr1.address)).start;
      const duration_ = (await vesting.vestingSchedules(addr1.address)).duration;
      await time.setNextBlockTimestamp(start_.add(duration_));

      await vesting.connect(addr1).claimTokens();
      expect(await token.balanceOf(addr1.address)).to.equal(100);

      await vesting.connect(addr2).claimTokens();
      expect(await token.balanceOf(addr2.address)).to.equal(200);
    });

    it("Should allow beneficiaries to claim only vested tokens after more than full duration", async () => {
      const start_ = (await vesting.vestingSchedules(addr1.address)).start;
      const duration_ = (await vesting.vestingSchedules(addr1.address)).duration;
      await time.setNextBlockTimestamp(start_.add(duration_).add(1000));

      await vesting.connect(addr1).claimTokens();
      expect(await token.balanceOf(addr1.address)).to.equal(100);

      await vesting.connect(addr2).claimTokens();
      expect(await token.balanceOf(addr2.address)).to.equal(200);
    });

    it("Should correctly claim total amount if claiming few times during claim period", async function () {
      const start_ = (await time.latest()) + 1000;
      const duration_ = 10000;

      await vesting.fix();

      await time.setNextBlockTimestamp(start_ + duration_ / 2);
      await vesting.connect(addr1).claimTokens();
      expect(await token.balanceOf(addr1.address)).to.equal(50);

      await time.setNextBlockTimestamp(start_ + (3 * duration_) / 4);
      await vesting.connect(addr1).claimTokens();
      expect(await token.balanceOf(addr1.address)).to.equal(75);

      await time.setNextBlockTimestamp(start_ + duration_ + 1000);
      await vesting.connect(addr1).claimTokens();
      expect(await token.balanceOf(addr1.address)).to.equal(100);
    });

    it("Should not allow beneficiaries to claim tokens before start period", async () => {
      await expect(vesting.connect(addr1).claimTokens()).to.be.revertedWith("Vesting: vesting not started");
    });

    it("Should not allow beneficiaries to claim more tokens than vested", async () => {
      const start_ = (await vesting.vestingSchedules(addr1.address)).start;
      await time.setNextBlockTimestamp(start_.add(5000));

      await vesting.connect(addr1).claimTokens();
      expect(await token.balanceOf(addr1.address)).to.equal(50);

      await expect(vesting.connect(addr1).claimTokens()).to.be.revertedWith("Vesting: no tokens to claim");
    });
  });

  describe("Get Claimable Amount", function () {
    beforeEach(async () => {
      const start_ = (await time.latest()) + 1000;
      const duration_ = 10000;
      await vesting.setVestingSchedule(addr1.address, 100, start_, duration_);
    });

    it("Should return zero claimable amount before start period", async () => {
      expect(await vesting.getClaimableAmount(addr1.address)).to.equal(0);
    });

    it("Should return correct claimable amount during vesting period", async () => {
      const start_ = (await vesting.vestingSchedules(addr1.address)).start;
      await time.increaseTo(start_.add(5000));
      expect(await vesting.getClaimableAmount(addr1.address)).to.equal(50);
    });

    it("Should return full claimable amount after full duration", async () => {
      const start_ = (await vesting.vestingSchedules(addr1.address)).start;
      const duration_ = (await vesting.vestingSchedules(addr1.address)).duration;
      await time.increaseTo(start_.add(duration_).add(100));
      expect(await vesting.getClaimableAmount(addr1.address)).to.equal(100);
    });
  });
});

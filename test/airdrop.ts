import { expect } from "chai";
import { ethers } from "hardhat";
import { Reverter } from "@/test/helpers/reverter";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { ERC20Mock, Airdrop } from "@ethers-v5";

describe("Airdrop", function () {
  let airdrop: Airdrop;
  let token: ERC20Mock;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr3: SignerWithAddress;
  let claimPeriodStart: number;
  let claimPeriodEnd: number;
  const reverter = new Reverter();

  before(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("ERC20Mock");
    token = (await Token.deploy("Mock Token", "MTK")) as ERC20Mock;
    await token.deployed();

    claimPeriodStart = (await time.latest()) + 1000;
    claimPeriodEnd = claimPeriodStart + 10000;

    const Airdrop = await ethers.getContractFactory("Airdrop");
    airdrop = (await Airdrop.deploy(
      token.address,
      owner.address,
      claimPeriodStart,
      claimPeriodEnd
    )) as Airdrop;
    await airdrop.deployed();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("Deployment", function () {
    it("Should set the correct token address", async () => {
      expect(await airdrop.token()).to.equal(token.address);
    });

    it("Should set the correct owner", async () => {
      expect(await airdrop.owner()).to.equal(owner.address);
    });

    it("Should set the correct claim period", async () => {
      expect(await airdrop.claimPeriodStart()).to.equal(claimPeriodStart);
      expect(await airdrop.claimPeriodEnd()).to.equal(claimPeriodEnd);
    });

    it("Should not allow zero address for token", async () => {
      const Airdrop = await ethers.getContractFactory("Airdrop");
      await expect(
        Airdrop.deploy(ethers.constants.AddressZero, owner.address, claimPeriodStart, claimPeriodEnd)
      ).to.be.revertedWith("Airdrop: zero token address");
    });

    it("Should not allow zero address for owner", async () => {
      const Airdrop = await ethers.getContractFactory("Airdrop");
      await expect(
        Airdrop.deploy(token.address, ethers.constants.AddressZero, claimPeriodStart, claimPeriodEnd)
      ).to.be.revertedWith("Airdrop: zero owner address");
    });

    it("Should not allow past start date", async () => {
      const pastTimestamp = (await time.latest()) - 1;
      const Airdrop = await ethers.getContractFactory("Airdrop");
      await expect(
        Airdrop.deploy(token.address, owner.address, pastTimestamp, claimPeriodEnd)
      ).to.be.revertedWith("Airdrop: start should be in the future");
    });

    it("Should not allow end date before start date", async () => {
      const Airdrop = await ethers.getContractFactory("Airdrop");
      await expect(
        Airdrop.deploy(token.address, owner.address, claimPeriodEnd, claimPeriodStart)
      ).to.be.revertedWith("Airdrop: start should be before end");
    });
  });

  describe("Set Recipients", function () {
    it("Should allow owner to set recipients", async () => {
      await airdrop.setRecipients([addr1.address, addr2.address], [100, 200]);
      expect(await airdrop.claimableTokens(addr1.address)).to.equal(100);
      expect(await airdrop.claimableTokens(addr2.address)).to.equal(200);
    });

    it("Should not allow non-owner to set recipients", async () => {
      await expect(airdrop.connect(addr1).setRecipients([addr1.address, addr2.address], [100, 200])).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("Should not allow setting recipients with different array lengths", async () => {
      await expect(airdrop.setRecipients([addr1.address], [100, 200])).to.be.revertedWith(
        "Airdrop: invalid array length"
      );
    });

    it("Should not allow setting a recipient more than once", async () => {
      await airdrop.setRecipients([addr1.address], [100]);
      await expect(airdrop.setRecipients([addr1.address], [200])).to.be.revertedWith(
        "Airdrop: recipient already set"
      );
    });
  });

  describe("Claim", function () {
    beforeEach(async () => {
      await token.mint(airdrop.address, 1000);
      await airdrop.setRecipients([addr1.address, addr2.address], [100, 200]);
    });

    it("Should allow recipients to claim tokens after start period", async () => {
      await time.increaseTo(claimPeriodStart + 1);

      await airdrop.connect(addr1).claim();
      expect(await token.balanceOf(addr1.address)).to.equal(100);
      expect(await airdrop.claimableTokens(addr1.address)).to.equal(0);
    });

    it("Should not allow recipients to claim tokens before start period", async () => {
      await expect(airdrop.connect(addr1).claim()).to.be.revertedWith("Airdrop: claim not started");
    });

    it("Should not allow recipients to claim tokens after end period", async () => {
      await time.increaseTo(claimPeriodEnd + 1);

      await expect(airdrop.connect(addr1).claim()).to.be.revertedWith("Airdrop: claim ended");
    });

    it("Should not allow recipients to claim tokens if they have none", async () => {
      await time.increaseTo(claimPeriodStart + 1);

      await expect(airdrop.connect(addr3).claim()).to.be.revertedWith("Airdrop: nothing to claim");
    });
  });

  describe("Withdraw", function () {
    it("Should allow owner to withdraw tokens", async () => {
      await token.mint(airdrop.address, 1000);
      await airdrop.withdraw(token.address, 500);
      expect(await token.balanceOf(owner.address)).to.equal(500);
    });

    it("Should not allow non-owner to withdraw tokens", async () => {
      await expect(airdrop.connect(addr1).withdraw(token.address, 500)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });
});

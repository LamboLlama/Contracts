import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { Reverter } from "@/test/helpers/reverter";
import { LamboLlama, EndpointMock } from "@ethers-v5";

describe("Ticket", async () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let DELEGATE: SignerWithAddress;
  let USER: SignerWithAddress;

  let lamboLlama: LamboLlama;

  before(async () => {
    [OWNER, DELEGATE, USER] = await ethers.getSigners();

    const LamboLlama = await ethers.getContractFactory("LamboLlama");
    const EndpointMock = await ethers.getContractFactory("EndpointMock");
    const lzEndpointMock = await EndpointMock.deploy();
    lamboLlama = await LamboLlama.deploy(
      DELEGATE.address,
      DELEGATE.address,
      100,
      100,
      100,
      DELEGATE.address,
      lzEndpointMock.address
    );

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("test", async () => {
    it("check delegate address as owner", async () => {
      expect(await lamboLlama.owner()).to.equal(DELEGATE.address);
      expect(await lamboLlama.balanceOf(DELEGATE.address)).to.equal(300);
    });
  });
});

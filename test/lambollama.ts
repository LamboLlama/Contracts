import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { Reverter } from "@/test/helpers/reverter";
import { LamboLlama } from "@ethers-v5";
import { splitSignature } from "ethers/lib/utils";

describe("LamboLlama", async () => {
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

    lamboLlama = await LamboLlama.deploy(DELEGATE.address, 100, true, lzEndpointMock.address);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("Token", async () => {
    it("check delegate address as owner", async () => {
      expect(await lamboLlama.owner()).to.equal(DELEGATE.address);
    });

    it("should transfer ownership", async () => {
      // Transfer ownership from DELEGATE to USER
      await lamboLlama.connect(DELEGATE).transferOwnership(USER.address);
      expect(await lamboLlama.owner()).to.equal(USER.address);
    });

    it("should mint tokens if _mintSupply is true", async () => {
      expect(await lamboLlama.balanceOf(DELEGATE.address)).to.equal(100);
    });

    it("should not mint tokens if _mintSupply is false", async () => {
      const LamboLlamaNoMint = await ethers.getContractFactory("LamboLlama");
      const EndpointMock = await ethers.getContractFactory("EndpointMock");
      const lzEndpointMock = await EndpointMock.deploy();
      const lamboLlamaNoMint = await LamboLlamaNoMint.deploy(DELEGATE.address, 100, false, lzEndpointMock.address);

      expect(await lamboLlamaNoMint.balanceOf(DELEGATE.address)).to.equal(0);
    });

    it("should transfer tokens between accounts", async () => {
      // Transfer 50 tokens from DELEGATE to USER
      await lamboLlama.connect(DELEGATE).transfer(USER.address, 50);
      expect(await lamboLlama.balanceOf(DELEGATE.address)).to.equal(50);
      expect(await lamboLlama.balanceOf(USER.address)).to.equal(50);
    });
  });

  describe("ERC20Permit", async () => {
    it("should allow USER to approve via permit and transfer tokens", async () => {
      const value = 50; // Amount to be approved
      const nonce = await lamboLlama.nonces(OWNER.address); // Get the current nonce for the owner
      const deadline = ethers.constants.MaxUint256; // Set a deadline far in the future

      // Define domain for signature (this info is part of ERC712)
      const domain = {
        name: await lamboLlama.name(),
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId, // Ensure correct chainId
        verifyingContract: lamboLlama.address
      };

      // Define permit types according to EIP-2612
      const types = {
        Permit: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
          { name: "value", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" }
        ]
      };

      // Prepare the permit data
      const permitData = {
        owner: OWNER.address,
        spender: USER.address,
        value: value,
        nonce: nonce,
        deadline: deadline
      };

      // Get the owner's signature
      const signature = await OWNER._signTypedData(domain, types, permitData);
      const { v, r, s } = splitSignature(signature); // Split signature into its parts

      // Send tokens to OWNER
      await lamboLlama.connect(DELEGATE).transfer(OWNER.address, value);

      // Call permit using the signed data
      await lamboLlama.permit(OWNER.address, USER.address, value, deadline, v, r, s);

      // Check that the allowance for USER has been updated after the permit
      const allowance = await lamboLlama.allowance(OWNER.address, USER.address);
      expect(allowance).to.equal(value);

      // Transfer tokens from OWNER to DELEGATE by USER
      await lamboLlama.connect(USER).transferFrom(OWNER.address, DELEGATE.address, value);

      // Check balances after the transfer
      const ownerBalance = await lamboLlama.balanceOf(OWNER.address);
      const delegateBalance = await lamboLlama.balanceOf(DELEGATE.address);

      expect(ownerBalance).to.equal(0); // OWNER's balance should now be 0 (initial was 50)
      expect(delegateBalance).to.equal(100); // DELEGATE's balance should increase by 50
    });
  });
});

import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { LamboLlama } from "@ethers-v5";

function bn(number: string) {
  return ethers.BigNumber.from(number);
}

describe.skip("permit", function () {
  let lll: LamboLlama;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const LamboLlama = await ethers.getContractFactory("LamboLlama");
    const EndpointMock = await ethers.getContractFactory("EndpointMock");
    const lzEndpointMock = await EndpointMock.deploy();
    lll = await LamboLlama.deploy(owner.address, bn("1000000000000000000000000"), lzEndpointMock.address);
  });

  it("Should allow permit and transferFrom", async function () {
    const nonce = await lll.nonces(owner.address);
    const deadline = Math.floor(Date.now() / 1000) + 60 * 60;

    const domain = {
      name: await lll.name(),
      version: "1",
      chainId: (await ethers.provider.getNetwork()).chainId,
      verifyingContract: lll.address,
    };

    const types = {
      Permit: [
        { name: "owner", type: "address" },
        { name: "spender", type: "address" },
        { name: "value", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint256" },
      ],
    };

    const value = {
      owner: owner.address,
      spender: addr1.address,
      value: ethers.utils.parseUnits("100"),
      nonce: nonce.toNumber(),
      deadline: deadline,
    };

    const signature = await owner._signTypedData(domain, types, value);
    const { v, r, s } = ethers.utils.splitSignature(signature);

    await lll.permit(owner.address, addr1.address, ethers.utils.parseUnits("100"), deadline, v, r, s);

    await lll.connect(addr1).transferFrom(owner.address, addr2.address, ethers.utils.parseUnits("100"));

    expect(await lll.balanceOf(addr2.address)).to.equal(ethers.utils.parseUnits("100"));
  });
});

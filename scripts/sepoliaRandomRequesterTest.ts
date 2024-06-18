// scripts/interact.js

const { ethers } = require("hardhat");

const myAddress = "0x9eCd08Fc708cDb77a33AFd83eb7f5ca4E4344766";

async function testRandomNums() {
  const signer = await ethers.provider.getSigner(myAddress);

  const random = await ethers.getContractAt("RandomRequesterMock", "0x9161cf6f4823c00B24eBE072a6BD8732Cc1b69A5");
  const linkToken = await ethers.getContractAt("IERC20", "0x779877A7B0D9E8603169DdbD7836e478b4624789");

  // await linkToken.transfer(random.address, ethers.BigNumber.from("3000000000000000000"));

  const response = await random.mockRequestRandomWords(6, { gasLimit: 700000 });
  console.log(response);
}

async function logRandomNums() {
  const random = await ethers.getContractAt("RandomRequesterMock", "0x9161cf6f4823c00B24eBE072a6BD8732Cc1b69A5");

  for (let i = 0; i < 6; i++) {
    const response = await random.nums(i);
    console.log(response);

    if (i < 5) {
      console.log("First num ", i, " ", response.mod(43));
    } else {
      console.log("First degen num ", " ", response.mod(10));
    }
  }
  console.log("--------------------------------------------------");

  for (let i = 0; i < 6; i++) {
    const response = await random.nums(i);

    const newNum = response.div(173);
    console.log(newNum);
    if (i < 5) {
      console.log("Second num ", i, " ", newNum.mod(43));
    } else {
      console.log("Second degen num ", " ", newNum.mod(10));
    }
  }
}

async function sendEmplyTx() {
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, ethers.provider);
  const gasPrice = ethers.utils.parseUnits("20", "gwei");
  await signer.sendTransaction({
    to: signer.address,
    gasPrice: gasPrice,
    value: 0,
    nonce: 117,
  });
}

sendEmplyTx()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

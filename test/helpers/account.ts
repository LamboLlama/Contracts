
import { BigNumber } from "ethers";

export class Account {
    setBalance = async (address: string, amount: BigNumber) => {
        await ethers.provider.send("hardhat_setBalance", [
            address,
            amount.toHexString(),
        ]);
    }
}
import { BigNumber, ethers } from "ethers";

export class Calculate {
    effectiveAmount(amount: BigNumber, amountContributed: BigNumber): BigNumber {
        // Bonus thresholds and rates as defined in the contract
        const bonusRates = [40, 30, 15]; // in percentage (regular numbers)
        const bonusThresholds = [
            BigNumber.from(ethers.utils.parseEther("15")),
            BigNumber.from(ethers.utils.parseEther("45")),
            BigNumber.from(ethers.utils.parseEther("90")),
        ];

        let remainingAmount = BigNumber.from(amount); // Amount to be distributed (BigNumber)
        let effectiveAmount = BigNumber.from(0); // Effective amount (BigNumber)
        let totalDeposited = BigNumber.from(amountContributed); // Start with already contributed amount (BigNumber)

        // Loop through the thresholds and apply bonuses
        for (let i = 0; i < bonusThresholds.length; i++) {
            let thresholdEnd = bonusThresholds[i];
            let currentBonusRate = BigNumber.from(bonusRates[i]);

            if (totalDeposited.gte(thresholdEnd)) {
                continue; // Skip thresholds that have already been filled by amountContributed
            }

            let remainingCapacity = thresholdEnd.sub(totalDeposited);

            if (remainingCapacity.isZero()) {
                continue;
            }

            let amountInThisThreshold = remainingAmount.lte(remainingCapacity) ? remainingAmount : remainingCapacity;

            if (amountInThisThreshold.isZero()) {
                continue;
            }

            // Apply the bonus rate
            let bonusAmount = amountInThisThreshold.mul(currentBonusRate).div(100); // Proper percentage calculation using BigNumber
            effectiveAmount = effectiveAmount.add(amountInThisThreshold).add(bonusAmount);
            totalDeposited = totalDeposited.add(amountInThisThreshold);
            remainingAmount = remainingAmount.sub(amountInThisThreshold);

            if (remainingAmount.isZero()) {
                break;
            }
        }

        // Handle any remaining amount that exceeds all thresholds, applying it without bonuses
        if (!remainingAmount.isZero()) {
            effectiveAmount = effectiveAmount.add(remainingAmount);
        }

        return effectiveAmount;
    }
}

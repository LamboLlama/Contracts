import { expect } from 'chai';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

import { Account } from '@/test/helpers/account';
import { Calculate } from '@/test/helpers/calculate';
import { Whitelist } from '@/test/helpers/whitelist';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { ERC20Mock, Presale } from '@ethers-v5';

describe('Presale Contract', function () {
	const account = new Account();
	const calculate = new Calculate();
	const whitelist = new Whitelist();

	let presale: Presale;
	let token: ERC20Mock;


	let whitelistStartTime: number;
	let whitelistEndTime: number;
	let fundingStartTime: number;
	let fundingEndTime: number;
	let claimStartTime: number;

	let totalTokensForSale: BigNumber;

	let owner: SignerWithAddress;
	let fundsWallet: SignerWithAddress;
	let whitelistSigner: SignerWithAddress;

	let investor1: SignerWithAddress;
	let investor2: SignerWithAddress;
	let investor3: SignerWithAddress;
	let investor4: SignerWithAddress;



	let otherAccounts: SignerWithAddress[];

	beforeEach(async function () {
		[owner, fundsWallet, whitelistSigner, investor1, investor2, investor3, investor4, ...otherAccounts] = await ethers.getSigners();

		await account.setBalance(investor1.address, ethers.utils.parseEther('10000000'));
		await account.setBalance(investor2.address, ethers.utils.parseEther('10000000'));
		await account.setBalance(investor3.address, ethers.utils.parseEther('10000000'));
		await account.setBalance(investor4.address, ethers.utils.parseEther('10000000'));

		// Deploy mock ERC20 token
		const TokenFactory = await ethers.getContractFactory('ERC20Mock');
		token = (await TokenFactory.deploy('Mock Token', 'MTK')) as ERC20Mock;
		await token.deployed();

		// Deploy the Presale contract
		const PresaleFactory = await ethers.getContractFactory('Presale');

		// Set funding and claim times
		const currentTime = await time.latest();
		whitelistStartTime = currentTime + 10; // Starts in 10 seconds
		whitelistEndTime = whitelistStartTime + 3600; // Ends in 1 hour
		fundingStartTime = whitelistEndTime + 10; // Starts in 10 seconds
		fundingEndTime = fundingStartTime + 3600; // Ends in 1 hour
		claimStartTime = fundingEndTime + 3600; // Claims start 1 hour after funding ends
		totalTokensForSale = ethers.utils.parseUnits('600000000', 18); // 600,000,000 tokens

		presale = (await PresaleFactory.deploy(
			token.address,
			whitelistStartTime,
			whitelistEndTime,
			fundingStartTime,
			fundingEndTime,
			claimStartTime,
			totalTokensForSale,
			fundsWallet.address,
			whitelistSigner.address,
		)) as Presale;

		await presale.deployed();

		// Mint tokens to the owner for depositing into the presale contract
		await token.mint(owner.address, totalTokensForSale);

		// Approve the presale contract to spend the owner's tokens
		await token.connect(owner).approve(presale.address, totalTokensForSale);

		// Owner deposits tokens into the presale contract
		await presale.connect(owner).depositTokens();

		// Fast forward to funding start time
		await time.increaseTo(whitelistStartTime + 1);
	});

	describe('Contract Deployment', function () {
		it('should deploy the contract with correct parameters', async function () {
			expect(await presale.token()).to.equal(token.address);
			expect(whitelistStartTime).to.equal((await presale.whitelistStartTime()).toNumber());
			expect(whitelistEndTime).to.equal((await presale.whitelistEndTime()).toNumber());
			expect(fundingStartTime).to.equal((await presale.fundingStartTime()).toNumber());
			expect(fundingEndTime).to.equal((await presale.fundingEndTime()).toNumber());
			expect(claimStartTime).to.equal((await presale.claimStartTime()).toNumber());
			expect(totalTokensForSale).to.equal(totalTokensForSale);
			expect(await presale.owner()).to.equal(owner.address);
			expect(await presale.fundsWallet()).to.equal(fundsWallet.address);
			expect(await presale.whitelistSigner()).to.equal(whitelistSigner.address);
		});

		describe('Presale Constructor Checks', function () {
			it('should revert if whitelist end time is before or equal to whitelist start time', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const invalidWhitelistEndTime = whitelistStartTime - 1; // End time before start time

				await expect(
					PresaleFactory.deploy(
						token.address,
						whitelistStartTime,
						invalidWhitelistEndTime,
						fundingStartTime,
						fundingEndTime,
						claimStartTime,
						totalTokensForSale,
						fundsWallet.address,
						whitelistSigner.address
					)
				).to.be.revertedWithCustomError(presale, 'InvalidWhitelistPeriod');
			});

			it('should revert if funding start time is before or equal to whitelist end time', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const invalidFundingStartTime = whitelistEndTime - 1;

				await expect(
					PresaleFactory.deploy(
						token.address,
						whitelistStartTime,
						whitelistEndTime,
						invalidFundingStartTime,
						fundingEndTime,
						claimStartTime,
						totalTokensForSale,
						fundsWallet.address,
						whitelistSigner.address
					)
				).to.be.revertedWithCustomError(presale, 'InvalidWhitelistPeriod');
			});

			it('should revert if funding end time is before or equal to funding start time', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const invalidFundingEndTime = fundingStartTime - 1;

				await expect(
					PresaleFactory.deploy(
						token.address,
						whitelistStartTime,
						whitelistEndTime,
						fundingStartTime,
						invalidFundingEndTime,
						claimStartTime,
						totalTokensForSale,
						fundsWallet.address,
						whitelistSigner.address
					)
				).to.be.revertedWithCustomError(presale, 'InvalidFundingPeriod');
			});

			it('should revert if claim start time is before or equal funding end time', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const invalidClaimStartTime = fundingEndTime - 1;

				await expect(
					PresaleFactory.deploy(
						token.address,
						whitelistStartTime,
						whitelistEndTime,
						fundingStartTime,
						fundingEndTime,
						invalidClaimStartTime,
						totalTokensForSale,
						fundsWallet.address,
						whitelistSigner.address
					)
				).to.be.revertedWithCustomError(presale, 'InvalidClaimPeriod');
			});

			it('should revert if total tokens for sale is zero', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const zeroTotalTokens = 0; // No tokens allocated for sale

				await expect(
					PresaleFactory.deploy(
						token.address,
						whitelistStartTime,
						whitelistEndTime,
						fundingStartTime,
						fundingEndTime,
						claimStartTime,
						zeroTotalTokens,
						fundsWallet.address,
						whitelistSigner.address
					)
				).to.be.revertedWithCustomError(presale, 'InvalidFundingPeriod');
			});

			it('should revert if funds wallet address is zero address', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const zeroAddress = ethers.constants.AddressZero; // Invalid wallet address

				await expect(
					PresaleFactory.deploy(
						token.address,
						whitelistStartTime,
						whitelistEndTime,
						fundingStartTime,
						fundingEndTime,
						claimStartTime,
						totalTokensForSale,
						zeroAddress,
						whitelistSigner.address
					)
				).to.be.revertedWithCustomError(presale, 'TransferFailed');
			});
		});
	});

	describe('Whitelisting Check', function () {
		it('should verify if an address is whitelisted using signature', async function () {
			const signature = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			expect(await presale.connect(investor1).isWhitelisted(signature)).to.be.true;

			// Check that a random signature does not work
			const fakeSignature = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);
			expect(await presale.connect(investor1).isWhitelisted(fakeSignature)).to.be.false;
		});
	});

	describe('Token Deposit', function () {
		it('should allow the owner to deposit tokens', async function () {
			// The owner already deposited tokens in beforeEach
			expect(await presale.tokensDeposited()).to.be.true;
			expect(await token.balanceOf(presale.address)).to.equal(totalTokensForSale);
		});

		it('should not allow non-owners to deposit tokens', async function () {
			await expect(presale.connect(investor1).depositTokens()).to.be.revertedWith(
				'Ownable: caller is not the owner'
			);
		});

		it('should not allow tokens to be deposited more than once', async function () {
			await expect(presale.connect(owner).depositTokens()).to.be.revertedWithCustomError(
				presale,
				'AlreadyDeposited'
			);
		});
	});

	describe('Contributions', function () {
		it('should accept contributions during funding period', async function () {
			await time.increaseTo(fundingStartTime + 1);

			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const initialFundsWalletBalance = await ethers.provider.getBalance(fundsWallet.address);

			await presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: contributionAmount });

			expect(await presale.totalEth()).to.equal(contributionAmount);

			const contribution = await presale.contributions(investor1.address);
			expect(contribution.amount).to.equal(contributionAmount);

			// Check that fundsWallet received the ETH
			const finalFundsWalletBalance = await ethers.provider.getBalance(fundsWallet.address);
			expect(finalFundsWalletBalance.sub(initialFundsWalletBalance)).to.equal(contributionAmount);
		});

		it('should reject zero contributions', async function () {
			await expect(presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: 0 })).to.be.revertedWithCustomError(
				presale,
				'TransferFailed'
			);
		});

		it('should reject contributions before funding period', async function () {
			// Fast forward to after funding end time
			const fundingStartTime = await presale.fundingStartTime();
			await time.setNextBlockTimestamp(fundingStartTime.sub(1));

			await expect(
				presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: ethers.utils.parseEther('1') })
			).to.be.revertedWithCustomError(presale, 'NotInFundingPeriod');
		});

		it('should handle multiple contributions from the same investor', async function () {
			const fundingStartTime = await presale.fundingStartTime();
			await time.increaseTo(fundingStartTime);

			const contributionAmount1 = ethers.utils.parseEther('5');
			const contributionAmount2 = ethers.utils.parseEther('10');

			await presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: contributionAmount1 });
			await presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: contributionAmount2 });

			const contribution = await presale.contributions(investor1.address);
			expect(contribution.amount).to.equal(contributionAmount1.add(contributionAmount2));
		});
	});

	describe('Contributions with Bonuses', function () {
		it('should correctly calculate effective amount with bonus within first threshold', async function () {
			const fundingStartTime = await presale.fundingStartTime();
			await time.increaseTo(fundingStartTime);

			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, totalEthEffectiveBefore);

			const tx = await presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor1.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();
			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should correctly calculate effective amount when contribution spans multiple thresholds', async function () {
			const fundingStartTime = await presale.fundingStartTime();
			await time.increaseTo(fundingStartTime);
			// Initial contribution to set totalEthEffectiveBefore
			const initialContributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			await presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: initialContributionAmount });

			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const contributionAmount = ethers.utils.parseEther('40');
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, initialContributionAmount);

			const tx = await presale.connect(investor2).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor2.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();

			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should correctly handle contributions after all thresholds are crossed', async function () {
			const fundingStartTime = await presale.fundingStartTime();
			await time.increaseTo(fundingStartTime);
			// Contributions to cross all thresholds
			const initialContributionAmount = ethers.utils.parseEther('35'); // 35 ETH
			await presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: initialContributionAmount });
			await presale.connect(investor2).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: initialContributionAmount });
			await presale.connect(investor3).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: initialContributionAmount });

			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const contributionAmount = BigNumber.from(ethers.utils.parseEther('105')); // 105 ETH
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, totalEthEffectiveBefore);

			const tx = await presale.connect(investor2).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor2.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();

			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should handle contributions exactly at threshold limits', async function () {
			const fundingStartTime = await presale.fundingStartTime();
			await time.increaseTo(fundingStartTime);
			// Contribute to reach exactly the first threshold
			const contributionAmount = ethers.utils.parseEther('15'); // 15 ETH
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, ethers.BigNumber.from(0));

			const tx = await presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: contributionAmount });

			const receipt = await tx.wait();

			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			// Verify that the totalEthEffective is as expected
			expect(await presale.totalEthEffective()).to.equal(expectedEffectiveAmount);
		});

		it('should calculate no bonus after all thresholds are met', async function () {
			const fundingStartTime = await presale.fundingStartTime();
			await time.increaseTo(fundingStartTime.add(1));
			// Contribute to meet all thresholds
			await presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: ethers.utils.parseEther('90') });

			const contributionAmount = ethers.utils.parseEther('95'); // Above all thresholds

			const tx = await presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: contributionAmount });

			const receipt = await tx.wait();

			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event?.args?.effectiveAmount).to.equal(contributionAmount); // No bonus, effective amount equals actual
		});

		it('should reject contributions when the funding period is over', async function () {
			// Move time to after the funding period
			const fundingEndTime = await presale.fundingEndTime();
			await time.increaseTo(fundingEndTime.add(1));

			await expect(
				presale.connect(investor1).contribute("0x0000000000000000000000000000000000000000000000000000000000000000", { value: ethers.utils.parseEther('1') })
			).to.be.revertedWithCustomError(presale, 'NotInFundingPeriod');
		});

		it('should correctly calculate effective amount with bonus within first threshold using fallback', async function () {
			const fundingStartTime = await presale.fundingStartTime();
			await time.increaseTo(fundingStartTime);

			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, totalEthEffectiveBefore);

			await investor1.sendTransaction({ to: presale.address, value: contributionAmount });

			const totalEthEffectiveAfter = await presale.totalEthEffective();
			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});
	});

	describe('Whitelist contributions', function () {
		it('should accept contributions during whitelist period', async function () {


			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const initialFundsWalletBalance = await ethers.provider.getBalance(fundsWallet.address);
			const signature = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			await presale.connect(investor1).contribute(signature, { value: contributionAmount });

			expect(await presale.totalEth()).to.equal(contributionAmount);

			const contribution = await presale.contributions(investor1.address);
			expect(contribution.amount).to.equal(contributionAmount);

			// Check that fundsWallet received the ETH
			const finalFundsWalletBalance = await ethers.provider.getBalance(fundsWallet.address);
			expect(finalFundsWalletBalance.sub(initialFundsWalletBalance)).to.equal(contributionAmount);
		});

		it('should reject zero contributions', async function () {
			const signature = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			await expect(presale.connect(investor1).contribute(signature, { value: 0 })).to.be.revertedWithCustomError(
				presale,
				'TransferFailed'
			);
		});

		it('should reject contributions of non whitelisted during whitelist period', async function () {
			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const signature = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);

			await expect(
				presale.connect(investor1).contribute(signature, { value: contributionAmount })
			).to.be.revertedWithCustomError(presale, 'NotWhitelisted');
		});
	});

	describe('Whitelist contributions with Bonuses', function () {
		it('should correctly calculate effective amount with bonus within first threshold', async function () {

			const signature = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, totalEthEffectiveBefore);

			const tx = await presale.connect(investor1).contribute(signature, { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor1.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();
			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should correctly calculate effective amount when contribution spans multiple thresholds', async function () {
			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const signature2 = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);

			// Initial contribution to set totalEthEffectiveBefore
			const initialContributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			await presale.connect(investor1).contribute(signature1, { value: initialContributionAmount });

			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const contributionAmount = ethers.utils.parseEther('40');
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, initialContributionAmount);

			const tx = await presale.connect(investor2).contribute(signature2, { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor2.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();

			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should correctly handle contributions after all thresholds are crossed', async function () {
			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const signature2 = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);
			const signature3 = await whitelist.generateWhitelistSignature(whitelistSigner, investor3);

			// Contributions to cross all thresholds
			const initialContributionAmount = ethers.utils.parseEther('35'); // 35 ETH
			await presale.connect(investor1).contribute(signature1, { value: initialContributionAmount });
			await presale.connect(investor2).contribute(signature2, { value: initialContributionAmount });
			await presale.connect(investor3).contribute(signature3, { value: initialContributionAmount });

			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const contributionAmount = BigNumber.from(ethers.utils.parseEther('105')); // 105 ETH
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, totalEthEffectiveBefore);

			const tx = await presale.connect(investor2).contribute(signature2, { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor2.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();

			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should handle contributions exactly at threshold limits', async function () {
			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);

			// Contribute to reach exactly the first threshold
			const contributionAmount = ethers.utils.parseEther('15'); // 15 ETH
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, ethers.BigNumber.from(0));

			const tx = await presale.connect(investor1).contribute(signature1, { value: contributionAmount });

			const receipt = await tx.wait();

			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			// Verify that the totalEthEffective is as expected
			expect(await presale.totalEthEffective()).to.equal(expectedEffectiveAmount);
		});

		it('should calculate no bonus after all thresholds are met', async function () {
			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);

			// Contribute to meet all thresholds
			await presale.connect(investor1).contribute(signature1, { value: ethers.utils.parseEther('90') });

			const contributionAmount = ethers.utils.parseEther('95'); // Above all thresholds

			const tx = await presale.connect(investor1).contribute(signature1, { value: contributionAmount });

			const receipt = await tx.wait();

			const event = receipt.events?.find((e) => e.event === 'DepositReceived');
			expect(event?.args?.effectiveAmount).to.equal(contributionAmount); // No bonus, effective amount equals actual
		});
	});

	describe('Claiming and Vesting', function () {
		beforeEach(async function () {
			const fundingStartTime = await presale.fundingStartTime();
			await time.increaseTo(fundingStartTime);
			// Contribute a large amount so we can claim later
			const contributionAmount1 = ethers.utils.parseEther('80'); // 80 ETH
			const contributionAmount2 = ethers.utils.parseEther('20'); // 20 ETH
			const contributionAmount3 = ethers.utils.parseEther('35'); // 20 ETH

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const signature2 = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);
			const signature3 = await whitelist.generateWhitelistSignature(whitelistSigner, investor3);

			await presale.connect(investor1).contribute(signature1, { value: contributionAmount1 });
			await presale.connect(investor2).contribute(signature2, { value: contributionAmount2 });
			await presale.connect(investor3).contribute(signature3, { value: contributionAmount3 });
		});

		it('should only allow claiming tokens after the claim start time', async function () {
			// Move back time to before the claim period starts
			const claimStartTime = await presale.claimStartTime();
			await time.setNextBlockTimestamp(claimStartTime.sub(1));

			await expect(presale.connect(investor1).claim()).to.be.revertedWithCustomError(
				presale,
				'ClaimPeriodNotStarted'
			);
		});

		it('should only allow claiming tokens if a contribution has been made', async function () {
			// Move back time to before the claim period starts
			const claimStartTime = (await presale.claimStartTime()).toNumber();
			await time.increaseTo(claimStartTime);

			await expect(presale.connect(investor4).claim()).to.be.revertedWithCustomError(
				presale,
				'NoContributionsToClaim'
			);
		});

		it('should allow a user to claim their immediate tokens', async function () {
			// Fast forward to the claim start time
			const claimStartTime = (await presale.claimStartTime()).toNumber();
			await time.increaseTo(claimStartTime);

			// Retrieve the user's contribution and calculate the immediate tokens
			const userContribution = await presale.contributions(investor3.address);
			const tokenBalanceBefore = await token.balanceOf(investor3.address);

			// Claim the tokens
			await presale.connect(investor3).claim();

			const tokenBalanceAfter = await token.balanceOf(investor3.address);
			const userUpdatedContribution = await presale.contributions(investor3.address);

			const immediateTokens = userContribution.amount
				.mul(await presale.totalTokensForSale())
				.div(await presale.totalEthEffective());
			// Check that the investor's balance increased by the expected immediate tokens
			expect(tokenBalanceAfter.sub(tokenBalanceBefore)).to.equal(immediateTokens);
			// Ensure the claim flag is set to true
			expect(userUpdatedContribution.claimed).to.be.true;
		});

		it('should correctly calculate vested bonus tokens over time', async function () {
			const userContribution = await presale.contributions(investor1.address);
			const totalBonusTokens = userContribution.effectiveAmount.sub(userContribution.amount); // Bonus tokens are based on effective amount minus actual contribution

			// Simulate partial vesting by setting the time to exactly halfway through the vesting period
			const vestingEndTime = (await presale.vestingEndTime()).toNumber();
			const claimStartTime = (await presale.claimStartTime()).toNumber();
			const halfwayVestingTime = claimStartTime + (vestingEndTime - claimStartTime) / 2;

			// Set the block time to exactly halfway through the vesting period
			await time.setNextBlockTimestamp(halfwayVestingTime);

			// Calculate how much should be vested at halfway point
			const expectedVestedAmount = totalBonusTokens.div(2); // Halfway through, 50% of bonus should be vested
			const tokenBalanceBefore = await token.balanceOf(investor1.address);

			await presale.connect(investor1).claim();

			const tokenBalanceAfter = await token.balanceOf(investor1.address);
			const userUpdatedContribution = await presale.contributions(investor1.address);
			const immediateTokens = userUpdatedContribution.amount
				.mul(await presale.totalTokensForSale())
				.div(await presale.totalEthEffective());

			// Assert that the claimed bonus tokens match the expected vested amount exactly
			expect(userUpdatedContribution.claimedBonusTokens).to.equal(expectedVestedAmount);
			expect(tokenBalanceAfter.sub(tokenBalanceBefore)).to.equal(expectedVestedAmount.add(immediateTokens));
		});

		it('should allow a user to claim all vested bonus tokens after vesting period ends', async function () {
			const userContribution = await presale.contributions(investor1.address);
			const totalBonusTokens = userContribution.effectiveAmount.sub(userContribution.amount); // Bonus tokens

			// Fast forward to after the vesting period ends
			const vestingEndTime = (await presale.vestingEndTime()).toNumber();
			await time.increaseTo(vestingEndTime + 1);

			const tokenBalanceBefore = await token.balanceOf(investor1.address);

			await presale.connect(investor1).claim();

			const tokenBalanceAfter = await token.balanceOf(investor1.address);
			const userUpdatedContribution = await presale.contributions(investor1.address);
			const immediateTokens = userUpdatedContribution.amount
				.mul(await presale.totalTokensForSale())
				.div(await presale.totalEthEffective());

			expect(userUpdatedContribution.claimedBonusTokens).to.equal(totalBonusTokens);
			expect(tokenBalanceAfter.sub(tokenBalanceBefore)).to.equal(totalBonusTokens.add(immediateTokens));
		});

		it('should not claim immediate tokens if already claimed', async function () {
			const userContribution = await presale.contributions(investor1.address);
			const totalBonusTokens = userContribution.effectiveAmount.sub(userContribution.amount); // Bonus tokens

			// Fast forward to after the vesting period ends
			const vestingEndTime = (await presale.vestingEndTime()).toNumber();
			await time.increaseTo(vestingEndTime + 1);

			const tokenBalanceBefore = await token.balanceOf(investor1.address);

			await presale.connect(investor1).claim();
			await time.increaseTo((await time.latest()) + 100);
			await presale.connect(investor1).claim();

			const tokenBalanceAfter = await token.balanceOf(investor1.address);
			const userUpdatedContribution = await presale.contributions(investor1.address);
			const immediateTokens = userUpdatedContribution.amount
				.mul(await presale.totalTokensForSale())
				.div(await presale.totalEthEffective());

			expect(userUpdatedContribution.claimedBonusTokens).to.equal(totalBonusTokens);
			expect(tokenBalanceAfter.sub(tokenBalanceBefore)).to.equal(totalBonusTokens.add(immediateTokens));
		});

		it('should claim no more bonuses if everything is claimed', async function () {
			const userContribution = await presale.contributions(investor1.address);
			const totalBonusTokens = userContribution.effectiveAmount.sub(userContribution.amount); // Bonus tokens

			// Fast forward to after the vesting period ends
			const vestingEndTime = (await presale.vestingEndTime()).toNumber();
			await time.increaseTo(vestingEndTime + 1);

			const tokenBalanceBefore = await token.balanceOf(investor1.address);

			await presale.connect(investor1).claim();

			const tokenBalanceAfter = await token.balanceOf(investor1.address);
			const userUpdatedContribution = await presale.contributions(investor1.address);
			const immediateTokens = userUpdatedContribution.amount
				.mul(await presale.totalTokensForSale())
				.div(await presale.totalEthEffective());

			expect(userUpdatedContribution.claimedBonusTokens).to.equal(totalBonusTokens);
			expect(tokenBalanceAfter.sub(tokenBalanceBefore)).to.equal(totalBonusTokens.add(immediateTokens));

			await time.increaseTo(vestingEndTime + 100);
			await presale.connect(investor1).claim();

			const tokenBalanceAfter2 = await token.balanceOf(investor1.address);
			const userUpdatedContribution2 = await presale.contributions(investor1.address);
			const immediateTokens2 = userUpdatedContribution2.amount
				.mul(await presale.totalTokensForSale())
				.div(await presale.totalEthEffective());

			expect(tokenBalanceAfter2).to.equal(tokenBalanceAfter);
			expect(immediateTokens2).to.equal(immediateTokens);
		});

		it('should revert if user tries to claim without any contribution', async function () {
			const claimStartTime = (await presale.claimStartTime()).toNumber();
			await time.increaseTo(claimStartTime);
			await expect(presale.connect(investor4).claim()).to.be.revertedWithCustomError(
				presale,
				'NoContributionsToClaim'
			);
		});
	});
});

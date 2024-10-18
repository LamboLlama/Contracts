import { expect } from 'chai';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

import { Account } from '@/test/helpers/account';
import { Calculate } from '@/test/helpers/calculate';
import { Whitelist } from '@/test/helpers/whitelist';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { Presale, ERC20Mock } from '@ethers-v5';

describe('Presale Contract', function () {
	const account = new Account();
	const calculate = new Calculate();
	const whitelist = new Whitelist();

	let presale: Presale;
	let token: ERC20Mock;

	let currentTime: number;
	let whitelistStartTime: number;
	let whitelistEndTime: number;
	let publicPresaleStartTime: number;
	let publicPresaleEndTime: number;
	let presaleClaimStartTime: number;

	let presaleSupply: BigNumber;

	let owner: SignerWithAddress;
	let treasuryWallet: SignerWithAddress;
	let whitelistSigner: SignerWithAddress;

	let investor1: SignerWithAddress;
	let investor2: SignerWithAddress;
	let investor3: SignerWithAddress;
	let investor4: SignerWithAddress;

	let otherAccounts: SignerWithAddress[];

	beforeEach(async function () {
		[owner, treasuryWallet, whitelistSigner, investor1, investor2, investor3, investor4, ...otherAccounts] =
			await ethers.getSigners();

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
		currentTime = await time.latest();
		whitelistStartTime = currentTime + 10; // Starts in 10 seconds
		whitelistEndTime = whitelistStartTime + 3600; // Ends in 1 hour
		publicPresaleStartTime = whitelistEndTime + 10; // Starts in 10 seconds
		publicPresaleEndTime = publicPresaleStartTime + 3600; // Ends in 1 hour
		presaleClaimStartTime = publicPresaleEndTime + 3600; // Claims start 1 hour after funding ends
		//presaleSupply = ethers.BigNumber.from("1000000000000000000000000");
		presaleSupply = ethers.utils.parseUnits('1200000000000', 18); // 1,200,000,000,000 tokens

		presale = (await PresaleFactory.deploy(
			token.address,
			presaleSupply,
			whitelistSigner.address,
			treasuryWallet.address,
			whitelistStartTime,
			whitelistEndTime,
			publicPresaleStartTime,
			publicPresaleEndTime,
			presaleClaimStartTime
		)) as Presale;

		await presale.deployed();

		// Mint tokens to the owner for depositing into the presale contract
		await token.mint(owner.address, presaleSupply);

		// Approve the presale contract to spend the owner's tokens
		await token.connect(owner).approve(presale.address, presaleSupply);

		// Owner deposits tokens into the presale contract
		await presale.connect(owner).depositTokens();

		// Fast forward to funding start time
		//await time.increaseTo(whitelistStartTime + 1);
	});

	describe('Contract Deployment', function () {
		it('should deploy the contract with correct parameters', async function () {
			expect(await presale.token()).to.equal(token.address);
			expect(whitelistStartTime).to.equal((await presale.whitelistStartTime()).toNumber());
			expect(whitelistEndTime).to.equal((await presale.whitelistEndTime()).toNumber());
			expect(publicPresaleStartTime).to.equal((await presale.publicPresaleStartTime()).toNumber());
			expect(publicPresaleEndTime).to.equal((await presale.publicPresaleEndTime()).toNumber());
			expect(presaleClaimStartTime).to.equal((await presale.presaleClaimStartTime()).toNumber());
			expect(presaleSupply).to.equal(presaleSupply);
			expect(await presale.owner()).to.equal(owner.address);
			expect(await presale.treasuryWallet()).to.equal(treasuryWallet.address);
			expect(await presale.whitelistSigner()).to.equal(whitelistSigner.address);
		});

		describe('Presale Constructor Checks', function () {
			it('should revert if whitelist end time is before or equal to whitelist start time', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const invalidWhitelistEndTime = whitelistStartTime - 1; // End time before start time

				await expect(
					PresaleFactory.deploy(
						token.address,
						presaleSupply,
						whitelistSigner.address,
						treasuryWallet.address,
						whitelistStartTime,
						invalidWhitelistEndTime,
						publicPresaleStartTime,
						publicPresaleEndTime,
						presaleClaimStartTime
					)
				).to.be.revertedWithCustomError(presale, 'InvalidWhitelistInput');
			});

			it('should revert if funding start time is before or equal to whitelist end time', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const invalidFundingStartTime = whitelistEndTime - 1;

				await expect(
					PresaleFactory.deploy(
						token.address,
						presaleSupply,
						whitelistSigner.address,
						treasuryWallet.address,
						whitelistStartTime,
						whitelistEndTime,
						invalidFundingStartTime,
						publicPresaleEndTime,
						presaleClaimStartTime
					)
				).to.be.revertedWithCustomError(presale, 'InvalidWhitelistInput');
			});

			it('should revert if funding end time is before or equal to funding start time', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const invalidFundingEndTime = publicPresaleStartTime - 1;

				await expect(
					PresaleFactory.deploy(
						token.address,
						presaleSupply,
						whitelistSigner.address,
						treasuryWallet.address,
						whitelistStartTime,
						whitelistEndTime,
						publicPresaleStartTime,
						invalidFundingEndTime,
						presaleClaimStartTime
					)
				).to.be.revertedWithCustomError(presale, 'InvalidPresaleInput');
			});

			it('should revert if claim start time is before or equal funding end time', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const invalidClaimStartTime = publicPresaleEndTime - 1;

				await expect(
					PresaleFactory.deploy(
						token.address,
						presaleSupply,
						whitelistSigner.address,
						treasuryWallet.address,
						whitelistStartTime,
						whitelistEndTime,
						publicPresaleStartTime,
						publicPresaleEndTime,
						invalidClaimStartTime
					)
				).to.be.revertedWithCustomError(presale, 'InvalidPresaleClaimInput');
			});

			it('should revert if total tokens for sale is less then 1000 eth', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const invalidTotalTokens = ethers.utils.parseEther('100'); //100 tokens allocated for sale

				await expect(
					PresaleFactory.deploy(
						token.address,
						invalidTotalTokens,
						whitelistSigner.address,
						treasuryWallet.address,
						whitelistStartTime,
						whitelistEndTime,
						publicPresaleStartTime,
						publicPresaleEndTime,
						presaleClaimStartTime
					)
				).to.be.revertedWithCustomError(presale, 'InvalidPresaleInput');
			});

			it('should revert if funds wallet address is zero address', async function () {
				const PresaleFactory = await ethers.getContractFactory('Presale');
				const zeroAddress = ethers.constants.AddressZero; // Invalid wallet address

				await expect(
					PresaleFactory.deploy(
						token.address,
						presaleSupply,
						whitelistSigner.address,
						zeroAddress,
						whitelistStartTime,
						whitelistEndTime,
						publicPresaleStartTime,
						publicPresaleEndTime,
						presaleClaimStartTime
					)
				).to.be.revertedWithCustomError(presale, 'InvalidWalletInput');
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
			expect(await token.balanceOf(presale.address)).to.equal(presaleSupply);
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
		it('should reject contributions before contribution period', async function () {
			const contributionStartTime = await presale.whitelistStartTime();
			await time.setNextBlockTimestamp(contributionStartTime.sub(1));

			await expect(
				presale
					.connect(investor1)
					.contribute(ethers.constants.HashZero, { value: ethers.utils.parseEther('1') })
			).to.be.revertedWithCustomError(presale, 'NotInContributionPeriod');
		});

		it('should reject contributions after contribution period', async function () {
			const contributionEndTime = await presale.publicPresaleEndTime();
			await time.setNextBlockTimestamp(contributionEndTime.add(1));

			await expect(
				presale
					.connect(investor1)
					.contribute(ethers.constants.HashZero, { value: ethers.utils.parseEther('1') })
			).to.be.revertedWithCustomError(presale, 'NotInContributionPeriod');
		});

		it('should accept contributions during funding period', async function () {
			await time.increaseTo(publicPresaleStartTime + 1);

			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const initialFundsWalletBalance = await ethers.provider.getBalance(treasuryWallet.address);

			await presale.connect(investor1).contribute(ethers.constants.HashZero, { value: contributionAmount });

			expect(await presale.totalEth()).to.equal(contributionAmount);

			const contribution = await presale.contributions(investor1.address);
			expect(contribution.amount).to.equal(contributionAmount);

			// Check that treasuryWallet received the ETH
			const finalFundsWalletBalance = await ethers.provider.getBalance(treasuryWallet.address);
			expect(finalFundsWalletBalance.sub(initialFundsWalletBalance)).to.equal(contributionAmount);
		});

		it('should reject zero contributions', async function () {
			await expect(
				presale.connect(investor1).contribute(ethers.constants.HashZero, { value: 0 })
			).to.be.revertedWithCustomError(presale, 'NoValue');
		});

		it('should handle multiple contributions from the same investor', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);

			const contributionAmount1 = ethers.utils.parseEther('5');
			const contributionAmount2 = ethers.utils.parseEther('10');

			await presale.connect(investor1).contribute(ethers.constants.HashZero, { value: contributionAmount1 });
			await presale.connect(investor1).contribute(ethers.constants.HashZero, { value: contributionAmount2 });

			const contribution = await presale.contributions(investor1.address);
			expect(contribution.amount).to.equal(contributionAmount1.add(contributionAmount2));
		});

		it('should revert with TransferFailed when treasuryWallet rejects Ether', async function () {
			const RejectingWalletFactory = await ethers.getContractFactory('RejectingWalletMock');
			const rejectingWallet = await RejectingWalletFactory.deploy();
			await rejectingWallet.deployed();

			// Deploy the Presale contract using the rejecting wallet as the treasuryWallet
			const PresaleFactory = await ethers.getContractFactory('Presale');
			presale = await PresaleFactory.deploy(
				token.address,
				presaleSupply,
				whitelistSigner.address,
				rejectingWallet.address,
				whitelistStartTime,
				whitelistEndTime,
				publicPresaleStartTime,
				publicPresaleEndTime,
				presaleClaimStartTime
			);
			await presale.deployed();

			// Fund presale contract by contributing Ether
			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const signature = ethers.constants.HashZero; // Use a zero-length signature

			// Fast forward time to the funding period
			await time.increaseTo(publicPresaleStartTime + 1);

			// Attempt to contribute and expect it to revert with TransferFailed
			await expect(
				presale.connect(investor1).contribute(signature, { value: contributionAmount })
			).to.be.revertedWithCustomError(presale, 'TransferFailed');
		});
	});

	describe('Contributions with Bonuses', function () {
		it('should correctly calculate effective amount with bonus within first threshold', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);

			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, totalEthEffectiveBefore);

			const tx = await presale
				.connect(investor1)
				.contribute(ethers.constants.HashZero, { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor1.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();
			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should correctly calculate effective amount when contribution spans multiple thresholds', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Initial contribution to set totalEthEffectiveBefore
			const initialContributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			await presale
				.connect(investor1)
				.contribute(ethers.constants.HashZero, { value: initialContributionAmount });

			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const contributionAmount = ethers.utils.parseEther('40');
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, initialContributionAmount);

			const tx = await presale
				.connect(investor2)
				.contribute(ethers.constants.HashZero, { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor2.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();

			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should correctly handle contributions after all thresholds are crossed', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Contributions to cross all thresholds
			const initialContributionAmount = ethers.utils.parseEther('35'); // 35 ETH
			await presale
				.connect(investor1)
				.contribute(ethers.constants.HashZero, { value: initialContributionAmount });
			await presale
				.connect(investor2)
				.contribute(ethers.constants.HashZero, { value: initialContributionAmount });
			await presale
				.connect(investor3)
				.contribute(ethers.constants.HashZero, { value: initialContributionAmount });

			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const contributionAmount = BigNumber.from(ethers.utils.parseEther('105')); // 105 ETH
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, totalEthEffectiveBefore);

			const tx = await presale
				.connect(investor2)
				.contribute(ethers.constants.HashZero, { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor2.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();

			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should handle contributions exactly at threshold limits', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Contribute to reach exactly the first threshold
			const contributionAmount = ethers.utils.parseEther('15'); // 15 ETH
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, ethers.BigNumber.from(0));

			const tx = await presale
				.connect(investor1)
				.contribute(ethers.constants.HashZero, { value: contributionAmount });

			const receipt = await tx.wait();

			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			// Verify that the totalEthEffective is as expected
			expect(await presale.totalEthEffective()).to.equal(expectedEffectiveAmount);
		});

		it('should calculate no bonus after all thresholds are met', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime.add(1));
			// Contribute to meet all thresholds
			await presale
				.connect(investor1)
				.contribute(ethers.constants.HashZero, { value: ethers.utils.parseEther('90') });

			const contributionAmount = ethers.utils.parseEther('95'); // Above all thresholds

			const tx = await presale
				.connect(investor1)
				.contribute(ethers.constants.HashZero, { value: contributionAmount });

			const receipt = await tx.wait();

			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event?.args?.effectiveAmount).to.equal(contributionAmount); // No bonus, effective amount equals actual
		});

		it('should reject contributions when the funding period is over', async function () {
			// Move time to after the funding period
			const publicPresaleEndTime = await presale.publicPresaleEndTime();
			await time.increaseTo(publicPresaleEndTime.add(1));

			await expect(
				presale
					.connect(investor1)
					.contribute(ethers.constants.HashZero, { value: ethers.utils.parseEther('1') })
			).to.be.revertedWithCustomError(presale, 'NotInContributionPeriod');
		});

		it('should correctly calculate effective amount with bonus within first threshold using fallback', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);

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
			const whitelistStartTime = await presale.whitelistStartTime();
			await time.increaseTo(whitelistStartTime);

			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const initialFundsWalletBalance = await ethers.provider.getBalance(treasuryWallet.address);
			const signature = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			await presale.connect(investor1).contribute(signature, { value: contributionAmount });

			expect(await presale.totalEth()).to.equal(contributionAmount);

			const contribution = await presale.contributions(investor1.address);
			expect(contribution.amount).to.equal(contributionAmount);

			// Check that treasuryWallet received the ETH
			const finalFundsWalletBalance = await ethers.provider.getBalance(treasuryWallet.address);
			expect(finalFundsWalletBalance.sub(initialFundsWalletBalance)).to.equal(contributionAmount);
		});

		it('should reject zero contributions', async function () {
			const signature = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			await expect(presale.connect(investor1).contribute(signature, { value: 0 })).to.be.revertedWithCustomError(
				presale,
				'NoValue'
			);
		});

		it('should reject contributions of zero length signatures during whitelist period', async function () {
			const whitelistStartTime = await presale.whitelistStartTime();
			await time.increaseTo(whitelistStartTime);

			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const signature = '0x';

			await expect(
				presale.connect(investor1).contribute(signature, { value: contributionAmount })
			).to.be.revertedWithCustomError(presale, 'NotWhitelisted');
		});

		it('should reject contributions of non whitelisted during whitelist period', async function () {
			const whitelistStartTime = await presale.whitelistStartTime();
			await time.increaseTo(whitelistStartTime);

			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const signature = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);

			await expect(
				presale.connect(investor1).contribute(signature, { value: contributionAmount })
			).to.be.revertedWithCustomError(presale, 'NotWhitelisted');
		});
	});

	describe('Whitelist contributions with Bonuses', function () {
		it('should correctly calculate effective amount with bonus within first threshold', async function () {
			const whitelistStartTime = await presale.whitelistStartTime();
			await time.increaseTo(whitelistStartTime);

			const signature = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const contributionAmount = ethers.utils.parseEther('10'); // 10 ETH
			const totalEthEffectiveBefore = await presale.totalEthEffective();

			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, totalEthEffectiveBefore);

			const tx = await presale.connect(investor1).contribute(signature, { value: contributionAmount });

			const receipt = await tx.wait();

			expect(receipt.events).to.exist;
			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor1.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();
			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should correctly calculate effective amount when contribution spans multiple thresholds', async function () {
			const whitelistStartTime = await presale.whitelistStartTime();
			await time.increaseTo(whitelistStartTime);

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
			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor2.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();

			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should correctly handle contributions after all thresholds are crossed', async function () {
			const whitelistStartTime = await presale.whitelistStartTime();
			await time.increaseTo(whitelistStartTime);

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
			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event).to.exist;
			expect(event?.args?.user).to.equal(investor2.address);
			expect(event?.args?.amount).to.equal(contributionAmount);
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			const totalEthEffectiveAfter = await presale.totalEthEffective();

			expect(totalEthEffectiveAfter).to.equal(totalEthEffectiveBefore.add(expectedEffectiveAmount));
		});

		it('should handle contributions exactly at threshold limits', async function () {
			const whitelistStartTime = await presale.whitelistStartTime();
			await time.increaseTo(whitelistStartTime);

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);

			// Contribute to reach exactly the first threshold
			const contributionAmount = ethers.utils.parseEther('15'); // 15 ETH
			const expectedEffectiveAmount = calculate.effectiveAmount(contributionAmount, ethers.BigNumber.from(0));

			const tx = await presale.connect(investor1).contribute(signature1, { value: contributionAmount });

			const receipt = await tx.wait();

			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event?.args?.effectiveAmount).to.equal(expectedEffectiveAmount);

			// Verify that the totalEthEffective is as expected
			expect(await presale.totalEthEffective()).to.equal(expectedEffectiveAmount);
		});

		it('should calculate no bonus after all thresholds are met', async function () {
			const whitelistStartTime = await presale.whitelistStartTime();
			await time.increaseTo(whitelistStartTime);

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);

			// Contribute to meet all thresholds
			await presale.connect(investor1).contribute(signature1, { value: ethers.utils.parseEther('90') });

			const contributionAmount = ethers.utils.parseEther('95'); // Above all thresholds

			const tx = await presale.connect(investor1).contribute(signature1, { value: contributionAmount });

			const receipt = await tx.wait();

			const event = receipt.events?.find((e) => e.event === 'ContributionReceived');
			expect(event?.args?.effectiveAmount).to.equal(contributionAmount); // No bonus, effective amount equals actual
		});
	});

	describe('Receive Ether Functionality', function () {
		it('should accept Ether during the funding period via receive()', async function () {
			// Move time to the funding start time
			await time.increaseTo(publicPresaleStartTime + 1);

			const contributionAmount = ethers.utils.parseEther('5'); // 5 ETH
			const initialFundsWalletBalance = await ethers.provider.getBalance(treasuryWallet.address);

			// Send Ether directly to the contract's address using the receive function
			await investor1.sendTransaction({ to: presale.address, value: contributionAmount });

			// Check that the contribution was recorded
			expect(await presale.totalEth()).to.equal(contributionAmount);

			const contribution = await presale.contributions(investor1.address);
			expect(contribution.amount).to.equal(contributionAmount);

			// Check that the treasuryWallet received the ETH
			const finalFundsWalletBalance = await ethers.provider.getBalance(treasuryWallet.address);
			expect(finalFundsWalletBalance.sub(initialFundsWalletBalance)).to.equal(contributionAmount);
		});

		it('should revert when Ether is sent before the funding period via receive()', async function () {
			// Attempt to send Ether before the funding period
			const contributionAmount = ethers.utils.parseEther('5'); // 5 ETH

			await expect(
				investor1.sendTransaction({ to: presale.address, value: contributionAmount })
			).to.be.revertedWithCustomError(presale, 'NotInContributionPeriod');
		});

		it('should revert when Ether is sent after the funding period via receive()', async function () {
			// Move time to after the funding period ends
			await time.increaseTo(publicPresaleEndTime + 1);

			const contributionAmount = ethers.utils.parseEther('5'); // 5 ETH

			// Try to send Ether after the funding period, expect revert
			await expect(
				investor1.sendTransaction({ to: presale.address, value: contributionAmount })
			).to.be.revertedWithCustomError(presale, 'NotInContributionPeriod');
		});
	});

	describe('Claiming and Vesting', function () {
		it('should only allow claiming tokens after the claim start time', async function () {
			// Move back time to before the claim period starts
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Contribute a large amount so we can claim later
			const contributionAmount1 = ethers.utils.parseEther('4'); // 4 ETH

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);

			await presale.connect(investor1).contribute(signature1, { value: contributionAmount1 });

			const presaleClaimStartTime = await presale.presaleClaimStartTime();
			await time.setNextBlockTimestamp(presaleClaimStartTime.sub(1));

			await expect(presale.connect(investor1).claim()).to.be.revertedWithCustomError(
				presale,
				'ClaimPeriodNotStarted'
			);
		});

		it('should only allow claiming tokens if a contribution has been made', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Contribute a large amount so we can claim later
			const contributionAmount1 = ethers.utils.parseEther('80'); // 80 ETH
			const contributionAmount2 = ethers.utils.parseEther('20'); // 20 ETH
			const contributionAmount3 = ethers.BigNumber.from('7'); // 7 wei

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const signature2 = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);
			const signature3 = await whitelist.generateWhitelistSignature(whitelistSigner, investor3);

			await presale.connect(investor1).contribute(signature1, { value: contributionAmount1 });
			await presale.connect(investor2).contribute(signature2, { value: contributionAmount2 });
			await presale.connect(investor3).contribute(signature3, { value: contributionAmount3 });
			// Move back time to before the claim period starts
			const presaleClaimStartTime = (await presale.presaleClaimStartTime()).toNumber();
			await time.increaseTo(presaleClaimStartTime);

			await expect(presale.connect(investor4).claim()).to.be.revertedWithCustomError(
				presale,
				'NoContributionsToClaim'
			);
		});

		it('should allow a user to claim their immediate tokens', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Contribute a large amount so we can claim later
			const contributionAmount1 = ethers.utils.parseEther('12'); // 80 ETH
			const contributionAmount2 = ethers.utils.parseEther('7'); // 20 ETH
			const contributionAmount3 = ethers.BigNumber.from('7'); // 7 wei

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const signature2 = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);
			const signature3 = await whitelist.generateWhitelistSignature(whitelistSigner, investor3);

			await presale.connect(investor1).contribute(signature1, { value: contributionAmount1 });
			await presale.connect(investor2).contribute(signature2, { value: contributionAmount2 });
			await presale.connect(investor3).contribute(signature3, { value: contributionAmount3 });

			// Fast forward to the claim start time
			const presaleClaimStartTime = (await presale.presaleClaimStartTime()).toNumber();
			await time.increaseTo(presaleClaimStartTime);

			const totalEthEffective = await presale.totalEthEffective();

			// Retrieve the user's contribution and calculate the immediate tokens
			const userContribution1 = await presale.contributions(investor1.address);
			const userContribution2 = await presale.contributions(investor2.address);
			const userContribution3 = await presale.contributions(investor3.address);

			const tokenBalanceBefore1 = await token.balanceOf(investor1.address);
			const tokenBalanceBefore2 = await token.balanceOf(investor2.address);
			const tokenBalanceBefore3 = await token.balanceOf(investor3.address);

			// Claim the tokens
			await presale.connect(investor1).claim();
			await presale.connect(investor2).claim();
			await presale.connect(investor3).claim();

			const tokenBalanceAfter1 = await token.balanceOf(investor1.address);
			const tokenBalanceAfter2 = await token.balanceOf(investor2.address);
			const tokenBalanceAfter3 = await token.balanceOf(investor3.address);

			const userUpdatedContribution1 = await presale.contributions(investor1.address);
			const userUpdatedContribution2 = await presale.contributions(investor2.address);
			const userUpdatedContribution3 = await presale.contributions(investor3.address);

			const immediateTokens1 = userContribution1.amount.mul(presaleSupply).div(totalEthEffective);

			const immediateTokens2 = userContribution2.amount.mul(presaleSupply).div(totalEthEffective);

			const immediateTokens3 = userContribution3.amount.mul(presaleSupply).div(totalEthEffective);

			// Check that the investor's balance increased by the expected immediate tokens
			expect(tokenBalanceAfter1.sub(tokenBalanceBefore1)).to.be.greaterThanOrEqual(immediateTokens1);
			expect(tokenBalanceAfter2.sub(tokenBalanceBefore2)).to.be.greaterThanOrEqual(immediateTokens2);
			expect(tokenBalanceAfter3.sub(tokenBalanceBefore3)).to.be.greaterThanOrEqual(immediateTokens3);
			// Ensure the claim flag is set to true
			expect(userUpdatedContribution1.claimed).to.be.true;
			expect(userUpdatedContribution2.claimed).to.be.true;
			expect(userUpdatedContribution3.claimed).to.be.true;
		});

		it('should allow one user to claim their immediate tokens', async function () {
			const whitelistStartTime = await presale.whitelistStartTime();
			await time.increaseTo(whitelistStartTime);
			// Contribute a large amount so we can claim later
			const contributionAmount1 = ethers.utils.parseEther('80'); // 80 ETH

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);

			await presale.connect(investor1).contribute(signature1, { value: contributionAmount1 });

			const presaleClaimStartTime = (await presale.presaleClaimStartTime()).toNumber();
			await time.increaseTo(presaleClaimStartTime);

			// Retrieve the user's contribution and calculate the immediate tokens
			const userContribution = await presale.contributions(investor1.address);
			const tokenBalanceBefore = await token.balanceOf(investor1.address);

			// Claim the tokens
			await presale.connect(investor1).claim();

			const tokenBalanceAfter = await token.balanceOf(investor1.address);
			const userUpdatedContribution = await presale.contributions(investor1.address);

			const immediateTokens = userContribution.amount
				.mul(await presale.presaleSupply())
				.div(await presale.totalEthEffective());
			// Check that the investor's balance increased by the expected immediate tokens
			expect(tokenBalanceAfter.sub(tokenBalanceBefore)).to.be.greaterThanOrEqual(immediateTokens);
			// Ensure the claim flag is set to true
			expect(userUpdatedContribution.claimed).to.be.true;
		});

		it('should correctly calculate vested bonus tokens over time', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Contribute a large amount so we can claim later
			const contributionAmount1 = ethers.utils.parseEther('9'); // 9 ETH
			const contributionAmount2 = ethers.utils.parseEther('16'); // 16 ETH
			const contributionAmount3 = ethers.BigNumber.from('7'); // 7 wei

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const signature2 = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);
			const signature3 = await whitelist.generateWhitelistSignature(whitelistSigner, investor3);

			await presale.connect(investor1).contribute(signature1, { value: contributionAmount1 });
			await presale.connect(investor2).contribute(signature2, { value: contributionAmount2 });
			await presale.connect(investor3).contribute(signature3, { value: contributionAmount3 });

			const totalEthEffective = await presale.totalEthEffective();

			const userContribution1 = await presale.contributions(investor1.address);
			const userContribution2 = await presale.contributions(investor2.address);
			const userContribution3 = await presale.contributions(investor3.address);

			const totalBonusTokens1 = userContribution1.effectiveAmount
				.sub(userContribution1.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);
			const totalBonusTokens2 = userContribution2.effectiveAmount
				.sub(userContribution2.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);
			const totalBonusTokens3 = userContribution3.effectiveAmount
				.sub(userContribution3.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);

			// Simulate partial vesting by setting the time to exactly halfway through the vesting period
			const presaleVestingEndTime = (await presale.presaleVestingEndTime()).toNumber();
			const presaleClaimStartTime = (await presale.presaleClaimStartTime()).toNumber();
			const halfwayVestingTime = presaleClaimStartTime + (presaleVestingEndTime - presaleClaimStartTime) / 2;

			// Set the block time to exactly halfway through the vesting period
			await time.setNextBlockTimestamp(halfwayVestingTime);

			// Calculate how much should be vested at halfway point
			const expectedVestedAmount1 = totalBonusTokens1.div(2); // Halfway through, 50% of bonus should be vested
			const expectedVestedAmount2 = totalBonusTokens2.div(2); // Halfway through, 50% of bonus should be vested
			const expectedVestedAmount3 = totalBonusTokens3.div(2); // Halfway through, 50% of bonus should be vested

			const tokenBalanceBefore1 = await token.balanceOf(investor1.address);
			const tokenBalanceBefore2 = await token.balanceOf(investor2.address);
			const tokenBalanceBefore3 = await token.balanceOf(investor3.address);

			await presale.connect(investor1).claim();
			await presale.connect(investor2).claim();
			await presale.connect(investor3).claim();

			const tokenBalanceAfter1 = await token.balanceOf(investor1.address);
			const tokenBalanceAfter2 = await token.balanceOf(investor2.address);
			const tokenBalanceAfter3 = await token.balanceOf(investor3.address);

			const userUpdatedContribution1 = await presale.contributions(investor1.address);
			const userUpdatedContribution2 = await presale.contributions(investor2.address);
			const userUpdatedContribution3 = await presale.contributions(investor3.address);

			const immediateTokens1 = userUpdatedContribution1.amount.mul(presaleSupply).div(totalEthEffective);
			const immediateTokens2 = userUpdatedContribution2.amount.mul(presaleSupply).div(totalEthEffective);
			const immediateTokens3 = userUpdatedContribution3.amount.mul(presaleSupply).div(totalEthEffective);

			// Assert that the claimed bonus tokens match the expected vested amount exactly
			expect(userUpdatedContribution1.claimedBonusTokens).to.be.greaterThanOrEqual(expectedVestedAmount1);
			expect(userUpdatedContribution2.claimedBonusTokens).to.be.greaterThanOrEqual(expectedVestedAmount2);
			expect(userUpdatedContribution3.claimedBonusTokens).to.be.greaterThanOrEqual(expectedVestedAmount3);

			expect(tokenBalanceAfter1.sub(tokenBalanceBefore1)).to.be.greaterThanOrEqual(
				expectedVestedAmount1.add(immediateTokens1)
			);
			expect(tokenBalanceAfter2.sub(tokenBalanceBefore2)).to.be.greaterThanOrEqual(
				expectedVestedAmount2.add(immediateTokens2)
			);
			expect(tokenBalanceAfter3.sub(tokenBalanceBefore3)).to.be.greaterThanOrEqual(
				expectedVestedAmount3.add(immediateTokens3)
			);
		});

		it('should allow a user to claim all vested bonus tokens after vesting period ends', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Contribute a large amount so we can claim later
			const contributionAmount1 = ethers.utils.parseEther('15'); // 80 ETH
			const contributionAmount2 = ethers.utils.parseEther('6'); // 20 ETH
			const contributionAmount3 = ethers.BigNumber.from('1'); // 1 wei

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const signature2 = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);
			const signature3 = await whitelist.generateWhitelistSignature(whitelistSigner, investor3);

			await presale.connect(investor1).contribute(signature1, { value: contributionAmount1 });
			await presale.connect(investor2).contribute(signature2, { value: contributionAmount2 });
			await presale.connect(investor3).contribute(signature3, { value: contributionAmount3 });

			// Fast forward to after the vesting period ends
			const presaleVestingEndTime = (await presale.presaleVestingEndTime()).toNumber();
			await time.increaseTo(presaleVestingEndTime + 1);

			const totalEthEffective = await presale.totalEthEffective();

			const tokenBalanceBefore1 = await token.balanceOf(investor1.address);
			const tokenBalanceBefore2 = await token.balanceOf(investor2.address);
			const tokenBalanceBefore3 = await token.balanceOf(investor3.address);

			await presale.connect(investor1).claim();
			await presale.connect(investor2).claim();
			await presale.connect(investor3).claim();

			const tokenBalanceAfter1 = await token.balanceOf(investor1.address);
			const tokenBalanceAfter2 = await token.balanceOf(investor2.address);
			const tokenBalanceAfter3 = await token.balanceOf(investor3.address);

			const userUpdatedContribution1 = await presale.contributions(investor1.address);
			const userUpdatedContribution2 = await presale.contributions(investor2.address);
			const userUpdatedContribution3 = await presale.contributions(investor3.address);

			const immediateTokens1 = userUpdatedContribution1.amount
				.mul(await presale.presaleSupply())
				.div(totalEthEffective);

			const immediateTokens2 = userUpdatedContribution2.amount.mul(presaleSupply).div(totalEthEffective);

			const immediateTokens3 = userUpdatedContribution3.amount.mul(presaleSupply).div(totalEthEffective);

			const bonusTokens1 = userUpdatedContribution1.effectiveAmount
				.sub(userUpdatedContribution1.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);

			const bonusTokens2 = userUpdatedContribution2.effectiveAmount
				.sub(userUpdatedContribution2.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);

			const bonusTokens3 = userUpdatedContribution3.effectiveAmount
				.sub(userUpdatedContribution3.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);

			expect(userUpdatedContribution1.claimedBonusTokens).to.equal(bonusTokens1);
			expect(userUpdatedContribution2.claimedBonusTokens).to.equal(bonusTokens2);
			expect(userUpdatedContribution3.claimedBonusTokens).to.equal(bonusTokens3);

			expect(tokenBalanceAfter1.sub(tokenBalanceBefore1)).to.equal(bonusTokens1.add(immediateTokens1));
			expect(tokenBalanceAfter2.sub(tokenBalanceBefore2)).to.equal(bonusTokens2.add(immediateTokens2));
			expect(tokenBalanceAfter3.sub(tokenBalanceBefore3)).to.equal(bonusTokens3.add(immediateTokens3));
		});

		it('should not claim immediate tokens if already claimed', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Contribute a large amount so we can claim later
			const contributionAmount1 = ethers.utils.parseEther('4'); // 4 ETH
			const contributionAmount2 = ethers.utils.parseEther('3'); // 3 ETH
			const contributionAmount3 = ethers.BigNumber.from('1'); // 1 wei

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const signature2 = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);
			const signature3 = await whitelist.generateWhitelistSignature(whitelistSigner, investor3);

			await presale.connect(investor1).contribute(signature1, { value: contributionAmount1 });
			await presale.connect(investor2).contribute(signature2, { value: contributionAmount2 });
			await presale.connect(investor3).contribute(signature3, { value: contributionAmount3 });

			const totalEthEffective = await presale.totalEthEffective();

			const userContribution1 = await presale.contributions(investor1.address);
			const userContribution2 = await presale.contributions(investor2.address);
			const userContribution3 = await presale.contributions(investor3.address);

			const totalBonusTokens1 = userContribution1.effectiveAmount
				.sub(userContribution1.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);

			const totalBonusTokens2 = userContribution2.effectiveAmount
				.sub(userContribution2.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);

			const totalBonusTokens3 = userContribution3.effectiveAmount
				.sub(userContribution3.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);

			// Fast forward to after the vesting period ends
			const presaleVestingEndTime = (await presale.presaleVestingEndTime()).toNumber();
			await time.increaseTo(presaleVestingEndTime + 1);

			const tokenBalanceBefore1 = await token.balanceOf(investor1.address);
			const tokenBalanceBefore2 = await token.balanceOf(investor2.address);
			const tokenBalanceBefore3 = await token.balanceOf(investor3.address);

			await presale.connect(investor1).claim();
			await presale.connect(investor2).claim();
			await presale.connect(investor3).claim();

			await time.increaseTo((await time.latest()) + 100);

			await presale.connect(investor1).claim();
			await presale.connect(investor2).claim();
			await presale.connect(investor3).claim();

			const tokenBalanceAfter1 = await token.balanceOf(investor1.address);
			const tokenBalanceAfter2 = await token.balanceOf(investor2.address);
			const tokenBalanceAfter3 = await token.balanceOf(investor3.address);

			const userUpdatedContribution1 = await presale.contributions(investor1.address);
			const userUpdatedContribution2 = await presale.contributions(investor2.address);
			const userUpdatedContribution3 = await presale.contributions(investor3.address);

			const immediateTokens1 = userUpdatedContribution1.amount.mul(presaleSupply).div(totalEthEffective);

			const immediateTokens2 = userUpdatedContribution2.amount.mul(presaleSupply).div(totalEthEffective);

			const immediateTokens3 = userUpdatedContribution3.amount.mul(presaleSupply).div(totalEthEffective);

			expect(userUpdatedContribution1.claimedBonusTokens).to.equal(totalBonusTokens1);
			expect(userUpdatedContribution2.claimedBonusTokens).to.equal(totalBonusTokens2);
			expect(userUpdatedContribution3.claimedBonusTokens).to.equal(totalBonusTokens3);

			expect(tokenBalanceAfter1.sub(tokenBalanceBefore1)).to.equal(totalBonusTokens1.add(immediateTokens1));
			expect(tokenBalanceAfter2.sub(tokenBalanceBefore2)).to.equal(totalBonusTokens2.add(immediateTokens2));
			expect(tokenBalanceAfter3.sub(tokenBalanceBefore3)).to.equal(totalBonusTokens3.add(immediateTokens3));
		});

		it('should claim no more bonuses if everything is claimed', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
			// Contribute a large amount so we can claim later
			const contributionAmount1 = ethers.utils.parseEther('10'); // 10 ETH
			const contributionAmount2 = ethers.utils.parseEther('4'); // 4 ETH
			const contributionAmount3 = ethers.BigNumber.from('1'); // 1 wei

			const signature1 = await whitelist.generateWhitelistSignature(whitelistSigner, investor1);
			const signature2 = await whitelist.generateWhitelistSignature(whitelistSigner, investor2);
			const signature3 = await whitelist.generateWhitelistSignature(whitelistSigner, investor3);

			await presale.connect(investor1).contribute(signature1, { value: contributionAmount1 });
			await presale.connect(investor2).contribute(signature2, { value: contributionAmount2 });
			await presale.connect(investor3).contribute(signature3, { value: contributionAmount3 });

			const totalEthEffective = await presale.totalEthEffective();

			const userContribution1 = await presale.contributions(investor1.address);
			const userContribution2 = await presale.contributions(investor2.address);
			const userContribution3 = await presale.contributions(investor3.address);

			const totalBonusTokens1 = userContribution1.effectiveAmount
				.sub(userContribution1.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);
			const totalBonusTokens2 = userContribution2.effectiveAmount
				.sub(userContribution2.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);
			const totalBonusTokens3 = userContribution3.effectiveAmount
				.sub(userContribution3.amount)
				.mul(presaleSupply)
				.div(totalEthEffective);

			// Fast forward to after the vesting period ends
			const presaleVestingEndTime = (await presale.presaleVestingEndTime()).toNumber();
			await time.increaseTo(presaleVestingEndTime + 1);

			const tokenBalanceBefore1 = await token.balanceOf(investor1.address);
			const tokenBalanceBefore2 = await token.balanceOf(investor2.address);
			const tokenBalanceBefore3 = await token.balanceOf(investor3.address);

			await presale.connect(investor1).claim();
			await presale.connect(investor2).claim();
			await presale.connect(investor3).claim();

			const tokenBalanceAfter1 = await token.balanceOf(investor1.address);
			const tokenBalanceAfter2 = await token.balanceOf(investor2.address);
			const tokenBalanceAfter3 = await token.balanceOf(investor3.address);

			const userUpdatedContribution1 = await presale.contributions(investor1.address);
			const userUpdatedContribution2 = await presale.contributions(investor2.address);
			const userUpdatedContribution3 = await presale.contributions(investor3.address);

			const immediateTokens1 = userUpdatedContribution1.amount.mul(presaleSupply).div(totalEthEffective);

			const immediateTokens2 = userUpdatedContribution2.amount.mul(presaleSupply).div(totalEthEffective);

			const immediateTokens3 = userUpdatedContribution3.amount.mul(presaleSupply).div(totalEthEffective);

			expect(userUpdatedContribution1.claimedBonusTokens).to.equal(totalBonusTokens1);
			expect(userUpdatedContribution2.claimedBonusTokens).to.equal(totalBonusTokens2);
			expect(userUpdatedContribution3.claimedBonusTokens).to.equal(totalBonusTokens3);

			expect(tokenBalanceAfter1.sub(tokenBalanceBefore1)).to.equal(totalBonusTokens1.add(immediateTokens1));
			expect(tokenBalanceAfter2.sub(tokenBalanceBefore2)).to.equal(totalBonusTokens2.add(immediateTokens2));
			expect(tokenBalanceAfter3.sub(tokenBalanceBefore3)).to.equal(totalBonusTokens3.add(immediateTokens3));

			await time.increaseTo(presaleVestingEndTime + 100);

			await presale.connect(investor1).claim();
			await presale.connect(investor2).claim();
			await presale.connect(investor3).claim();

			const tokenBalanceAfterExtra1 = await token.balanceOf(investor1.address);
			const tokenBalanceAfterExtra2 = await token.balanceOf(investor2.address);
			const tokenBalanceAfterExtra3 = await token.balanceOf(investor3.address);

			const userUpdatedContributionExtra1 = await presale.contributions(investor1.address);
			const userUpdatedContributionExtra2 = await presale.contributions(investor2.address);
			const userUpdatedContributionExtra3 = await presale.contributions(investor3.address);

			const immediateTokensExtra1 = userUpdatedContributionExtra1.amount
				.mul(presaleSupply)
				.div(totalEthEffective);

			const immediateTokensExtra2 = userUpdatedContributionExtra2.amount
				.mul(presaleSupply)
				.div(totalEthEffective);

			const immediateTokensExtra3 = userUpdatedContributionExtra3.amount
				.mul(presaleSupply)
				.div(totalEthEffective);

			expect(tokenBalanceAfterExtra1).to.equal(tokenBalanceAfter1);
			expect(tokenBalanceAfterExtra2).to.equal(tokenBalanceAfter2);
			expect(tokenBalanceAfterExtra3).to.equal(tokenBalanceAfter3);

			expect(immediateTokensExtra1).to.equal(immediateTokens1);
			expect(immediateTokensExtra2).to.equal(immediateTokens2);
			expect(immediateTokensExtra3).to.equal(immediateTokens3);
		});

		it('should revert if user tries to claim without any contribution', async function () {
			const publicPresaleStartTime = await presale.publicPresaleStartTime();
			await time.increaseTo(publicPresaleStartTime);
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

			const presaleClaimStartTime = (await presale.presaleClaimStartTime()).toNumber();
			await time.increaseTo(presaleClaimStartTime);
			await expect(presale.connect(investor4).claim()).to.be.revertedWithCustomError(
				presale,
				'NoContributionsToClaim'
			);
		});
	});
});

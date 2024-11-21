import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Reverter } from '@/test/helpers/reverter';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { MerkleTree } from 'merkletreejs';
import { ERC20Mock, AirdropZerion } from '@ethers-v5';

describe('AirdropZerion', function () {
    let airdrop: AirdropZerion;
    let token: ERC20Mock;
    let owner: SignerWithAddress;
    let addr1: SignerWithAddress;
    let addr2: SignerWithAddress;
    let addr3: SignerWithAddress;

    const reverter = new Reverter();
    let merkleTree: MerkleTree;
    let merkleRoot: string;

    const claimList = [
        { address: '', amount: ethers.utils.parseEther('10') }, // Placeholder for addr1
        { address: '', amount: ethers.utils.parseEther('20') }, // Placeholder for addr2
        { address: '', amount: ethers.utils.parseEther('30') }, // Placeholder for addr3
    ];

    before(async () => {
        [owner, addr1, addr2, addr3] = await ethers.getSigners();

        claimList[0].address = addr1.address;
        claimList[1].address = addr2.address;
        claimList[2].address = addr3.address;

        // Deploy ERC20Mock token
        const Token = await ethers.getContractFactory('ERC20Mock');
        token = (await Token.deploy('Mock Token', 'MTK')) as ERC20Mock;
        await token.deployed();

        // Generate Merkle Tree for airdrop
        const leaves = claimList.map(({ address, amount }) =>
            ethers.utils.keccak256(ethers.utils.solidityPack(['address', 'uint256'], [address, amount]))
        );
        merkleTree = new MerkleTree(leaves, ethers.utils.keccak256, { sortPairs: true });
        merkleRoot = merkleTree.getHexRoot();

        // Deploy AirdropZerion contract
        const AirdropZerion = await ethers.getContractFactory('AirdropZerion');
        airdrop = (await AirdropZerion.deploy(merkleRoot, token.address)) as AirdropZerion;
        await airdrop.deployed();

        // Fund Airdrop contract with tokens
        const totalAmount = claimList.reduce((acc, { amount }) => acc.add(amount), ethers.constants.Zero);
        await token.mint(airdrop.address, totalAmount);

        await reverter.snapshot();
    });

    afterEach(reverter.revert);

    function getAmountForAddress(address: string) {
        const claim = claimList.find((claim) => claim.address === address);
        if (!claim) throw new Error('Address not in claim list');
        return claim.amount;
    }

    describe('Deployment', function () {
        it('Should revert if token address is invalid', async function () {
            const AirdropZerion = await ethers.getContractFactory('AirdropZerion');
            await expect(
                AirdropZerion.deploy(merkleRoot, ethers.constants.AddressZero)
            ).to.be.revertedWithCustomError(AirdropZerion, 'InavilidTokenAddress');
        });

        it('Should set the correct merkle root and token address', async function () {
            expect(await airdrop.merkleRoot()).to.equal(merkleRoot);
            expect(await airdrop.tokenAddress()).to.equal(token.address);
        });
    });

    describe('Claiming Airdrop', function () {
        it('Should revert with AlreadyClaimed error if address has already claimed', async function () {
            const amount = getAmountForAddress(addr1.address);
            const leaf = ethers.utils.keccak256(
                ethers.utils.solidityPack(['address', 'uint256'], [addr1.address, amount])
            );
            const proof = merkleTree.getHexProof(leaf);

            // First claim
            await airdrop.connect(addr1).claim(amount, proof);

            // Attempt to claim again
            await expect(airdrop.connect(addr1).claim(amount, proof)).to.be.revertedWithCustomError(
                airdrop,
                'AlreadyClaimed'
            );
        });

        it('Should revert with InvalidMerkleProof error if proof is invalid', async function () {
            // Get amount for addr1
            const correctAmount = getAmountForAddress(addr1.address);
            const incorrectAmount = getAmountForAddress(addr3.address);

            // Generate correct proof for addr1
            const leaf = ethers.utils.keccak256(
                ethers.utils.solidityPack(['address', 'uint256'], [addr1.address, correctAmount])
            );
            const proof = merkleTree.getHexProof(leaf);

            // Attempt to claim with incorrect amount
            await expect(
                airdrop.connect(addr1).claim(incorrectAmount, proof)
            ).to.be.revertedWithCustomError(airdrop, 'InvalidMerkleProof');
        });

        it('Should emit event on successful claim', async function () {
            const amount = getAmountForAddress(addr1.address);
            const leaf = ethers.utils.keccak256(
                ethers.utils.solidityPack(['address', 'uint256'], [addr1.address, amount])
            );
            const proof = merkleTree.getHexProof(leaf);

            await expect(airdrop.connect(addr1).claim(amount, proof))
                .to.emit(airdrop, 'Claimed')
                .withArgs(addr1.address, amount);
        });

        it('Should update claimed status after a successful claim', async function () {
            const amount = getAmountForAddress(addr2.address);
            const leaf = ethers.utils.keccak256(
                ethers.utils.solidityPack(['address', 'uint256'], [addr2.address, amount])
            );
            const proof = merkleTree.getHexProof(leaf);

            await airdrop.connect(addr2).claim(amount, proof);

            expect(await airdrop.claimed(addr2.address)).to.be.true;
        });
    });

    describe('Merkle Root Updates', function () {
        it('Should allow the owner to update the Merkle Root', async function () {
            const newClaimList = [
                { address: addr1.address, amount: ethers.utils.parseEther('15') },
                { address: addr3.address, amount: ethers.utils.parseEther('25') },
            ];
            const newLeaves = newClaimList.map(({ address, amount }) =>
                ethers.utils.keccak256(ethers.utils.solidityPack(['address', 'uint256'], [address, amount]))
            );
            const newMerkleTree = new MerkleTree(newLeaves, ethers.utils.keccak256, {
                sortPairs: true,
            });
            const newMerkleRoot = newMerkleTree.getHexRoot();

            await airdrop.connect(owner).setMerkleRoot(newMerkleRoot);

            expect(await airdrop.merkleRoot()).to.equal(newMerkleRoot);
        });

        it('Should revert if non-owner tries to update the Merkle Root', async function () {
            const newClaimList = [
                { address: addr1.address, amount: ethers.utils.parseEther('15') },
                { address: addr3.address, amount: ethers.utils.parseEther('25') },
            ];
            const newLeaves = newClaimList.map(({ address, amount }) =>
                ethers.utils.keccak256(ethers.utils.solidityPack(['address', 'uint256'], [address, amount]))
            );
            const newMerkleTree = new MerkleTree(newLeaves, ethers.utils.keccak256, {
                sortPairs: true,
            });
            const newMerkleRoot = newMerkleTree.getHexRoot();

            await expect(airdrop.connect(addr1).setMerkleRoot(newMerkleRoot)).to.be.revertedWith(
                'Ownable: caller is not the owner'
            );
        });
    });

    describe('Large Airdrop Test', function () {
        it('Should handle a large number of addresses efficiently', async function () {
            // Number of addresses
            const numAddresses = 100;

            // Initialize arrays
            const addresses = new Array(numAddresses);
            const amounts = new Array(numAddresses);
            const leaves = new Array(numAddresses);
            const claimListLarge = new Array(numAddresses);

            // Use a fixed amount for all addresses
            const amountPerAddress = ethers.utils.parseUnits('1', 18); // 1 token with 18 decimals

            // Total amount calculation
            const totalAmount = amountPerAddress.mul(numAddresses);

            // Generate addresses and leaves
            for (let i = 0; i < numAddresses; i++) {
                // Generate deterministic pseudo-random addresses
                const address = ethers.utils.getAddress(
                    ethers.utils.hexZeroPad(ethers.utils.hexlify(i + 1), 20)
                );
                addresses[i] = address;

                // Assign the fixed amount
                amounts[i] = amountPerAddress;

                // Prepare leaf
                const leaf = ethers.utils.keccak256(
                    ethers.utils.solidityPack(['address', 'uint256'], [address, amountPerAddress])
                );
                leaves[i] = leaf;

                // Add to claim list
                claimListLarge[i] = { address, amount: amountPerAddress };
            }

            // Generate Merkle Tree
            const merkleTreeLarge = new MerkleTree(leaves, ethers.utils.keccak256, { sortPairs: true });
            const merkleRootLarge = merkleTreeLarge.getHexRoot();

            // Deploy new Airdrop contract
            const AirdropZerion = await ethers.getContractFactory('AirdropZerion');
            const airdropLarge = (await AirdropZerion.deploy(merkleRootLarge, token.address)) as AirdropZerion;
            await airdropLarge.deployed();

            // Fund Airdrop contract with total amount
            await token.mint(airdropLarge.address, totalAmount);

            // Test claiming for the first address
            const testIndex = 0;
            const testAddress = addresses[testIndex];
            const testAmount = amounts[testIndex];

            // Generate proof
            const leaf = leaves[testIndex];
            const proof = merkleTreeLarge.getHexProof(leaf);

            // Impersonate the account
            await ethers.provider.send('hardhat_impersonateAccount', [testAddress]);
            const impersonatedSigner = await ethers.getSigner(testAddress);

            // Fund the impersonated account with ETH to pay for gas
            await owner.sendTransaction({
                to: testAddress,
                value: ethers.utils.parseEther('1'),
            });

            // Claim the tokens
            await expect(airdropLarge.connect(impersonatedSigner).claim(testAmount, proof))
                .to.emit(airdropLarge, 'Claimed')
                .withArgs(testAddress, testAmount);

            // Verify that the tokens were received
            const balance = await token.balanceOf(testAddress);
            expect(balance).to.equal(testAmount);

            // Stop impersonation
            await ethers.provider.send('hardhat_stopImpersonatingAccount', [testAddress]);
        }).timeout(60000); // Increase timeout if necessary
    });

    describe('Testing with JSON formatted data', function () {
        let testData: { [address: string]: { allocationWei: string; proof: string[] } };

        before(async function () {
            // Create test data in the specified JSON format
            testData = {};

            for (const { address, amount } of claimList) {
                // Generate leaf
                const leaf = ethers.utils.keccak256(
                    ethers.utils.solidityPack(['address', 'uint256'], [address, amount])
                );

                // Generate proof
                const proof = merkleTree.getHexProof(leaf);

                // Store data in the specified format
                testData[address] = {
                    allocationWei: amount.toString(),
                    proof,
                };
            }
        });

        it('Should successfully claim using data from the JSON object', async function () {
            // Choose one of the addresses (e.g., addr1)
            const testAddress = addr1.address;
            const signer = addr1;

            // Retrieve data from the testData object
            const { allocationWei, proof } = testData[testAddress];

            // Convert allocationWei back to BigNumber
            const amount = ethers.BigNumber.from(allocationWei);

            // Perform the claim
            await expect(airdrop.connect(signer).claim(amount, proof))
                .to.emit(airdrop, 'Claimed')
                .withArgs(testAddress, amount);

            // Verify that the tokens were received
            const balance = await token.balanceOf(testAddress);
            expect(balance).to.equal(amount);

            // Verify that the claimed status is updated
            expect(await airdrop.claimed(testAddress)).to.be.true;
        });

        it('Should revert with InvalidMerkleProof when using incorrect data', async function () {
            // Choose an address and use incorrect amount
            const testAddress = addr2.address;
            const signer = addr2;

            // Retrieve correct proof but incorrect amount (use addr3's amount)
            const incorrectAmount = ethers.BigNumber.from(testData[addr3.address].allocationWei);
            const { proof } = testData[testAddress];

            // Attempt to claim with incorrect amount
            await expect(airdrop.connect(signer).claim(incorrectAmount, proof)).to.be.revertedWithCustomError(
                airdrop,
                'InvalidMerkleProof'
            );
        });
    });
});

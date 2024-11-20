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
    const tokenAmount = ethers.utils.parseEther('10'); // 10 tokens per claim

    before(async () => {
        [owner, addr1, addr2, addr3] = await ethers.getSigners();

        // Deploy ERC20Mock token
        const Token = await ethers.getContractFactory('ERC20Mock');
        token = (await Token.deploy('Mock Token', 'MTK')) as ERC20Mock;
        await token.deployed();

        // Generate Merkle Tree for airdrop
        const leaves = [addr1.address, addr2.address, addr3.address].map((addr) =>
            ethers.utils.keccak256(ethers.utils.solidityPack(['address'], [addr]))
        );
        merkleTree = new MerkleTree(leaves, ethers.utils.keccak256, { sortPairs: true });
        merkleRoot = merkleTree.getHexRoot();

        // Deploy AirdropZerion contract
        const AirdropZerion = await ethers.getContractFactory('AirdropZerion');
        airdrop = (await AirdropZerion.deploy(merkleRoot, token.address, tokenAmount)) as AirdropZerion;
        await airdrop.deployed();

        // Fund Airdrop contract with tokens
        await token.mint(airdrop.address, ethers.utils.parseEther('1000'));

        await reverter.snapshot();
    });

    afterEach(reverter.revert);

    describe('Deployment', function () {
        it('Should revert if token amount is zero', async function () {
            const AirdropZerion = await ethers.getContractFactory('AirdropZerion');
            await expect(
                AirdropZerion.deploy(merkleRoot, token.address, ethers.constants.Zero)
            ).to.be.revertedWithCustomError(AirdropZerion, 'InvalidTokenAmount');
        });

        it('Should revert if token address is invalid', async function () {
            const AirdropZerion = await ethers.getContractFactory('AirdropZerion');
            await expect(
                AirdropZerion.deploy(merkleRoot, ethers.constants.AddressZero, tokenAmount)
            ).to.be.revertedWithCustomError(AirdropZerion, 'InavilidTokenAddress');
        });

        it('Should set the correct merkle root, token address, and token amount', async function () {
            expect(await airdrop.merkleRoot()).to.equal(merkleRoot);
            expect(await airdrop.tokenAddress()).to.equal(token.address);
            expect(await airdrop.tokenAmount()).to.equal(tokenAmount);
        });
    });

    describe('Claiming Airdrop', function () {
        it('Should revert with AlreadyClaimed error if address has already claimed', async function () {
            const proof = merkleTree.getHexProof(
                ethers.utils.keccak256(ethers.utils.solidityPack(['address'], [addr1.address]))
            );

            // First claim
            await airdrop.connect(addr1).claim(proof);

            // Attempt to claim again
            await expect(airdrop.connect(addr1).claim(proof)).to.be.revertedWithCustomError(airdrop, 'AlreadyClaimed');
        });

        it('Should revert with InvalidMerkleProof error if proof is invalid', async function () {
            // Generate an invalid proof
            const invalidProof = merkleTree.getHexProof(
                ethers.utils.keccak256(ethers.utils.solidityPack(['address'], [addr3.address]))
            );

            // Use addr1 to claim with addr3's proof
            await expect(airdrop.connect(addr1).claim(invalidProof)).to.be.revertedWithCustomError(
                airdrop,
                'InvalidMerkleProof'
            );
        });

        it('Should emit event on successful claim', async function () {
            const proof = merkleTree.getHexProof(
                ethers.utils.keccak256(ethers.utils.solidityPack(['address'], [addr1.address]))
            );

            await expect(airdrop.connect(addr1).claim(proof))
                .to.emit(airdrop, 'Claimed')
                .withArgs(addr1.address, tokenAmount);
        });

        it('Should update claimed status after a successful claim', async function () {
            const proof = merkleTree.getHexProof(
                ethers.utils.keccak256(ethers.utils.solidityPack(['address'], [addr2.address]))
            );

            await airdrop.connect(addr2).claim(proof);

            expect(await airdrop.claimed(addr2.address)).to.be.true;
        });
    });

    describe('Merkle Root Updates', function () {
        it('Should allow the owner to update the Merkle Root', async function () {
            const newLeaves = [addr1.address, addr3.address].map((addr) =>
                ethers.utils.keccak256(ethers.utils.solidityPack(['address'], [addr]))
            );
            const newMerkleTree = new MerkleTree(newLeaves, ethers.utils.keccak256, {
                sortPairs: true,
            });
            const newMerkleRoot = newMerkleTree.getHexRoot();

            await airdrop.connect(owner).setMerkleRoot(newMerkleRoot);

            expect(await airdrop.merkleRoot()).to.equal(newMerkleRoot);
        });

        it('Should revert if non-owner tries to update the Merkle Root', async function () {
            const newLeaves = [addr1.address, addr3.address].map((addr) =>
                ethers.utils.keccak256(ethers.utils.solidityPack(['address'], [addr]))
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
});

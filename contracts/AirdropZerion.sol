// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AirdropZerion is Ownable {
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    address public tokenAddress;

    event Claimed(address indexed claimant, uint256 amount);

    error AlreadyClaimed();
    error InvalidMerkleProof();
    error InavilidTokenAddress();
    error NoTokensToWithdraw();

    constructor(bytes32 _merkleRoot, address _tokenAddress) {
        if (_tokenAddress == address(0)) {
            revert InavilidTokenAddress();
        }

        merkleRoot = _merkleRoot;
        tokenAddress = _tokenAddress;
    }

    // Update the Merkle Root if necessary
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 amount, bytes32[] calldata proof) external {
        if (claimed[msg.sender]) {
            revert AlreadyClaimed();
        }

        if (!verify(msg.sender, amount, proof)) {
            revert InvalidMerkleProof();
        }

        claimed[msg.sender] = true;

        // Transfer tokens to the claimant
        IERC20(tokenAddress).transfer(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    function verify(
        address claimant,
        uint256 amount,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimant, amount));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // New method to withdraw tokens
    function withdrawTokens() external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) {
            revert NoTokensToWithdraw();
        }
        token.transfer(owner(), balance);
    }
}

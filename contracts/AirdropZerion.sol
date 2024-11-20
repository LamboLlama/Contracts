// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AirdropZerion is Ownable {
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    uint256 public tokenAmount;
    address public tokenAddress;

    event Claimed(address indexed claimant, uint256 amount);

    error AlreadyClaimed();
    error InvalidMerkleProof();
    error InvalidTokenAmount();
    error InavilidTokenAddress();

    constructor(bytes32 _merkleRoot, address _tokenAddress, uint256 _tokenAmount) {
        if (_tokenAmount == 0) {
            revert InvalidTokenAmount();
        }

        if (_tokenAddress == address(0)) {
            revert InavilidTokenAddress();
        }

        merkleRoot = _merkleRoot;
        tokenAmount = _tokenAmount;
        tokenAddress = _tokenAddress;
    }

    // Update the Merkle Root if necessary
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claim(bytes32[] calldata proof) external {
        if (claimed[msg.sender]) {
            revert AlreadyClaimed();
        }

        if (!verify(msg.sender, proof)) {
            revert InvalidMerkleProof();
        }

        claimed[msg.sender] = true;

        // Transfer Lambo Llama ($LLL) tokens to the claimant
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        emit Claimed(msg.sender, tokenAmount);
    }

    function verify(address claimant, bytes32[] calldata proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimant));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}

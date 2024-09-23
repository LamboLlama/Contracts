// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Airdrop is Ownable {
    IERC20 public token;
    mapping(address => uint256) public claimableTokens;
    mapping(address => uint256) public claimedTokens; // track claimed tokens
    uint256 public totalClaimable;
    uint256 public claimPeriodStart;
    uint256 public claimPeriodEnd;

    uint256 public constant VESTING_PERIOD = 180 days; // 6 months

    event HasClaimed(address indexed recipient, uint256 amount);

    // Custom errors
    error ZeroTokenAddress();
    error ZeroOwnerAddress();
    error ClaimStartInThePast();
    error ClaimEndBeforeStart();
    error InvalidArrayLength();
    error RecipientAlreadySet();
    error ClaimNotStarted();
    error ClaimEnded();
    error NothingToClaim();
    error NothingVestedToClaim();

    constructor(
        IERC20 token_,
        address owner_,
        uint256 claimPeriodStart_,
        uint256 claimPeriodEnd_
    ) Ownable() {
        if (address(token_) == address(0)) revert ZeroTokenAddress();
        if (owner_ == address(0)) revert ZeroOwnerAddress();
        if (claimPeriodStart_ <= block.timestamp) revert ClaimStartInThePast();
        if (claimPeriodEnd_ <= claimPeriodStart_) revert ClaimEndBeforeStart();

        token = token_;
        claimPeriodStart = claimPeriodStart_;
        claimPeriodEnd = claimPeriodEnd_;
        _transferOwnership(owner_);
    }

    function setRecipients(
        address[] calldata recipients_,
        uint256[] calldata claimableAmount_
    ) external onlyOwner {
        if (recipients_.length != claimableAmount_.length) revert InvalidArrayLength();
        uint256 sum = totalClaimable;
        for (uint256 i = 0; i < recipients_.length; i++) {
            if (claimableTokens[recipients_[i]] != 0) revert RecipientAlreadySet();
            claimableTokens[recipients_[i]] = claimableAmount_[i];
            unchecked {
                sum += claimableAmount_[i];
            }
        }

        totalClaimable = sum;
    }

    function claim() public {
        if (block.timestamp < claimPeriodStart) revert ClaimNotStarted();
        if (block.timestamp >= claimPeriodEnd) revert ClaimEnded();

        uint256 totalClaimableAmount = claimableTokens[msg.sender];
        if (totalClaimableAmount == 0) revert NothingToClaim();

        // Calculate the vested amount based on time passed
        uint256 timePassed = block.timestamp - claimPeriodStart;
        uint256 vestedAmount = (totalClaimableAmount * timePassed) / VESTING_PERIOD;

        // Ensure the user doesn't claim more than the total vested amount
        uint256 claimableNow = vestedAmount - claimedTokens[msg.sender];
        if (claimableNow == 0) revert NothingVestedToClaim();

        // Update claimedTokens and transfer the claimable amount
        claimedTokens[msg.sender] += claimableNow;
        token.transfer(msg.sender, claimableNow);

        emit HasClaimed(msg.sender, claimableNow);
    }

    function withdraw(IERC20 token_, uint256 amount_) external onlyOwner {
        IERC20(token_).transfer(msg.sender, amount_);
    }
}

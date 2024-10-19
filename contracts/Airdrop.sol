// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Airdrop Contract
 * @dev This contract handles the distribution of tokens through an airdrop with a vesting period.
 * Beneficiaries can claim their tokens over time, based on a linear vesting schedule.
 * The owner can set the recipients and their claimable amounts before the claim period starts.
 */
contract Airdrop is Ownable {
    /// @notice The ERC20 token being distributed in the airdrop
    IERC20 public token;

    /// @notice Mapping to store the claimable tokens for each recipient
    mapping(address => uint256) public claimableTokens;

    /// @notice Mapping to track how many tokens each recipient has already claimed
    mapping(address => uint256) public claimedTokens;

    /// @notice Total number of tokens allocated for the airdrop
    uint256 public totalClaimable;

    /// @notice Timestamp when the claim period starts
    uint256 public claimPeriodStart;

    /// @notice Timestamp when the claim period ends
    uint256 public claimPeriodEnd;

    /// @dev Vesting period duration (in seconds), set to 180 days (6 months)
    uint256 public constant VESTING_PERIOD = 180 days;

    /// @notice Event emitted when a recipient claims tokens
    /// @param recipient The address of the recipient claiming tokens
    /// @param amount The number of tokens claimed
    event HasClaimed(address indexed recipient, uint256 amount);

    // Custom Errors for gas-efficient error handling
    error ZeroTokenAddress(); // Thrown when the token address is zero
    error ZeroOwnerAddress(); // Thrown when the owner address is zero
    error ClaimStartInThePast(); // Thrown when claim start time is set in the past
    error ClaimEndBeforeStart(); // Thrown when claim end time is set before the claim start time
    error InvalidArrayLength(); // Thrown when the length of recipients and claimableAmount arrays do not match
    error RecipientAlreadySet(); // Thrown when trying to set claimable tokens for a recipient more than once
    error ClaimNotStarted(); // Thrown when attempting to claim tokens before the claim period starts
    error ClaimEnded(); // Thrown when attempting to claim tokens after the claim period has ended
    error NothingToClaim(); // Thrown when there are no tokens available to claim
    error NothingVestedToClaim(); // Thrown when there are no vested tokens to claim

    /**
     * @dev Constructor to initialize the airdrop contract
     * @param token_ The ERC20 token being distributed
     * @param owner_ The owner of the contract (who can set recipients and withdraw tokens)
     * @param claimPeriodStart_ The timestamp when the claim period starts
     * @param claimPeriodEnd_ The timestamp when the claim period ends
     */
    constructor(
        IERC20 token_,
        address owner_,
        uint256 claimPeriodStart_,
        uint256 claimPeriodEnd_
    ) Ownable() {
        if (address(token_) == address(0)) revert ZeroTokenAddress(); // Ensure the token address is valid
        if (owner_ == address(0)) revert ZeroOwnerAddress(); // Ensure a valid owner address
        if (claimPeriodStart_ <= block.timestamp) revert ClaimStartInThePast(); // Ensure the claim period doesn't start in the past
        if (claimPeriodEnd_ <= claimPeriodStart_) revert ClaimEndBeforeStart(); // Ensure claim period ends after it starts

        token = token_; // Set the token to be distributed
        claimPeriodStart = claimPeriodStart_; // Set the start time of the claim period
        claimPeriodEnd = claimPeriodEnd_; // Set the end time of the claim period
        _transferOwnership(owner_); // Transfer ownership to the specified owner
    }

    /**
     * @dev Sets the recipients and their respective claimable token amounts
     * Can only be called by the owner
     * @param recipients_ The array of recipient addresses
     * @param claimableAmount_ The array of token amounts claimable by each recipient
     */
    function setRecipients(
        address[] calldata recipients_,
        uint256[] calldata claimableAmount_
    ) external onlyOwner {
        if (recipients_.length != claimableAmount_.length) revert InvalidArrayLength(); // Ensure both arrays have the same length

        uint256 sum = totalClaimable; // Track total claimable tokens
        for (uint256 i = 0; i < recipients_.length; i++) {
            if (claimableTokens[recipients_[i]] != 0) revert RecipientAlreadySet(); // Ensure recipient is not already set

            claimableTokens[recipients_[i]] = claimableAmount_[i]; // Set the claimable amount for each recipient
            unchecked {
                sum += claimableAmount_[i]; // Accumulate total claimable tokens
            }
        }

        totalClaimable = sum; // Update total claimable tokens
    }

    /**
     * @dev Allows recipients to claim their vested tokens based on the time that has passed since the claim period started.
     */
    function claim() public {
        if (block.timestamp < claimPeriodStart) revert ClaimNotStarted(); // Ensure the claim period has started
        if (block.timestamp >= claimPeriodEnd) revert ClaimEnded(); // Ensure the claim period has not ended

        uint256 totalClaimableAmount = claimableTokens[msg.sender]; // Get the total claimable amount for the caller
        if (totalClaimableAmount == 0) revert NothingToClaim(); // Ensure the caller has tokens to claim

        // Calculate the amount of time that has passed since the claim period started
        uint256 timePassed = block.timestamp - claimPeriodStart;

        // Calculate the vested amount based on the elapsed time
        uint256 vestedAmount = (totalClaimableAmount * timePassed) / VESTING_PERIOD;

        // Calculate how many tokens are claimable now (vested amount minus already claimed tokens)
        uint256 claimableNow = vestedAmount - claimedTokens[msg.sender];
        if (claimableNow == 0) revert NothingVestedToClaim(); // Ensure there are vested tokens available to claim

        // Update claimedTokens mapping to track how many tokens have been claimed
        claimedTokens[msg.sender] += claimableNow;

        // Transfer the claimable tokens to the caller
        token.transfer(msg.sender, claimableNow);

        // Emit the claim event
        emit HasClaimed(msg.sender, claimableNow);
    }

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens from the contract, except the airdrop tokens if needed.
     * @param token_ The ERC20 token address to withdraw (can be any token except the airdrop token).
     * @param amount_ The amount of tokens to withdraw.
     */
    function withdraw(IERC20 token_, uint256 amount_) external onlyOwner {
        IERC20(token_).transfer(msg.sender, amount_); // Transfer the specified token to the owner
    }
}

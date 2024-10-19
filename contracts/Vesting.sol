// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Vesting Contract
 * @dev This contract handles the vesting of tokens for team members or other beneficiaries.
 * Tokens are released gradually over a specified duration, starting at a defined time.
 * The owner can configure the vesting schedules before locking the contract configuration.
 */
contract Vesting is Ownable {
    /// @dev Structure to store vesting schedule information for each beneficiary
    struct VestingSchedule {
        uint256 totalAmount; // Total number of tokens to be vested
        uint256 claimedAmount; // Amount of tokens already claimed by the beneficiary
        uint256 start; // Timestamp when vesting starts
        uint256 duration; // Duration over which vesting occurs (in seconds)
    }

    /// @dev Flag to indicate if the vesting schedule has been finalized
    bool public configuratedAndFixed;

    /// @dev The ERC20 token to be vested
    IERC20 public token;

    /// @dev Mapping of beneficiary addresses to their corresponding vesting schedules
    mapping(address => VestingSchedule) public vestingSchedules;

    /// @dev Event emitted when tokens are claimed by a beneficiary
    event TokensClaimed(address indexed beneficiary, uint256 amount);

    // Custom errors for more gas-efficient error handling
    error ZeroTokenAddress(); // Thrown when a zero address is provided for the token
    error ZeroBeneficiaryAddress(); // Thrown when a zero address is provided for the beneficiary
    error ZeroTotalAmount(); // Thrown when zero total amount is provided for vesting
    error ZeroDuration(); // Thrown when zero duration is provided for vesting
    error VestingNotStarted(); // Thrown when attempting to claim tokens before vesting start
    error NoTokensToClaim(); // Thrown when there are no tokens to claim
    error ContractFixed(); // Thrown when trying to modify the contract after it is fixed
    error WithdrawVestingTokenNotAllowed(); // Thrown when attempting to withdraw the vesting token

    /**
     * @dev Constructor to initialize the contract with the ERC20 token to be vested
     * @param token_ The ERC20 token address that will be vested
     */
    constructor(IERC20 token_) {
        if (address(token_) == address(0)) revert ZeroTokenAddress(); // Ensure the token address is valid
        token = token_; // Set the token to be vested
    }

    /// @dev Modifier to allow certain actions only before the vesting configuration is locked
    modifier onlyBeforeConfiguratedAndFixed() {
        if (configuratedAndFixed) revert ContractFixed(); // Prevent modifications if the contract is locked
        _;
    }

    /**
     * @dev Locks the contract configuration, preventing further changes to vesting schedules
     */
    function fix() external onlyOwner {
        configuratedAndFixed = true; // Set the configuration as fixed
    }

    /**
     * @dev Withdraws all tokens from the contract before the configuration is locked
     * Can only be called by the owner before the contract is fixed
     */
    function withdraw() external onlyOwner onlyBeforeConfiguratedAndFixed {
        token.transfer(msg.sender, token.balanceOf(address(this))); // Transfer all tokens to the owner
    }

    /**
     * @dev Withdraws any ERC20 tokens that are accidentally sent to the contract, except for the vesting token
     * @param token_ The address of the ERC20 token to withdraw
     */
    function withdrawStuckERC20(IERC20 token_) external onlyOwner {
        if (address(token_) == address(token)) revert WithdrawVestingTokenNotAllowed(); // Prevent withdrawing the vesting token
        token_.transfer(msg.sender, token_.balanceOf(address(this))); // Transfer the specified token to the owner
    }

    /**
     * @dev Sets the vesting schedule for a specific beneficiary
     * Can only be called by the owner before the contract is fixed
     * @param beneficiary_ The address of the beneficiary
     * @param totalAmount_ The total amount of tokens to be vested for the beneficiary
     * @param start_ The start time (timestamp) for vesting
     * @param duration_ The duration over which the vesting occurs (in seconds)
     */
    function setVestingSchedule(
        address beneficiary_,
        uint256 totalAmount_,
        uint256 start_,
        uint256 duration_
    ) external onlyOwner onlyBeforeConfiguratedAndFixed {
        if (beneficiary_ == address(0)) revert ZeroBeneficiaryAddress(); // Ensure a valid beneficiary address
        if (totalAmount_ == 0) revert ZeroTotalAmount(); // Ensure a valid total amount of tokens
        if (duration_ == 0) revert ZeroDuration(); // Ensure a valid vesting duration

        // Set the vesting schedule for the beneficiary
        vestingSchedules[beneficiary_] = VestingSchedule({
            totalAmount: totalAmount_,
            claimedAmount: 0, // Initially, no tokens have been claimed
            start: start_, // Set the start time for vesting
            duration: duration_ // Set the vesting duration
        });
    }

    /**
     * @dev Allows a beneficiary to claim their vested tokens
     * The amount of claimable tokens depends on the elapsed time and the vesting schedule
     */
    function claimTokens() external {
        VestingSchedule storage schedule_ = vestingSchedules[msg.sender]; // Get the vesting schedule for the caller

        if (block.timestamp <= schedule_.start) revert VestingNotStarted(); // Ensure vesting has started

        uint256 elapsedTime_ = block.timestamp - schedule_.start; // Calculate elapsed time since vesting started

        // If the elapsed time exceeds the vesting duration, cap it to the duration
        if (elapsedTime_ > schedule_.duration) {
            elapsedTime_ = schedule_.duration;
        }

        // Calculate the total vested amount based on the elapsed time
        uint256 vestedAmount_ = (schedule_.totalAmount * elapsedTime_) / schedule_.duration;
        uint256 claimableAmount_ = vestedAmount_ - schedule_.claimedAmount; // Calculate claimable tokens

        if (claimableAmount_ == 0) revert NoTokensToClaim(); // Ensure there are tokens to claim

        // Update the claimed amount and transfer tokens to the caller
        schedule_.claimedAmount += claimableAmount_;
        token.transfer(msg.sender, claimableAmount_);

        // Emit an event for the token claim
        emit TokensClaimed(msg.sender, claimableAmount_);
    }

    /**
     * @dev Returns the number of claimable tokens for a given beneficiary at the current time
     * @param beneficiary_ The address of the beneficiary
     * @return The amount of claimable tokens
     */
    function getClaimableAmount(address beneficiary_) external view returns (uint256) {
        VestingSchedule storage schedule_ = vestingSchedules[beneficiary_]; // Get the vesting schedule for the beneficiary

        if (block.timestamp <= schedule_.start) {
            return 0; // If vesting hasn't started, there are no claimable tokens
        }

        uint256 elapsedTime_ = block.timestamp - schedule_.start; // Calculate the elapsed time since vesting started

        // If the elapsed time exceeds the vesting duration, cap it to the duration
        if (elapsedTime_ > schedule_.duration) {
            elapsedTime_ = schedule_.duration;
        }

        // Calculate the total vested amount based on the elapsed time
        uint256 vestedAmount_ = (schedule_.totalAmount * elapsedTime_) / schedule_.duration;

        // Return the claimable amount (vested amount minus claimed amount)
        return vestedAmount_ - schedule_.claimedAmount;
    }
}

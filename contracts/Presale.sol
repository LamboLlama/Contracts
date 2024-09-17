// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Presale is ReentrancyGuard {
    IERC20 public token;
    uint256 public fundingStartTime;
    uint256 public fundingEndTime;

    uint256 public claimStartTime;
    uint256 public vestingEndTime; // 1 month after claimStartTime

    uint256 public totalEth; // Actual ETH deposited
    uint256 public totalEthEffective; // Effective ETH after bonus
    uint256 public totalTokensForSale;

    uint256[] public bonusRates;
    uint256[] public bonusThresholds;

    struct Contribution {
        uint256 amount; // Actual ETH invested
        uint256 effectiveAmount; // Effective ETH after bonus
        uint256 bonusTokens; // Total bonus tokens allocated
        uint256 claimedBonusTokens; // Bonus tokens already claimed
        bool claimed; // Whether immediate tokens have been claimed
    }

    mapping(address => Contribution) public contributions;
    bool public tokensDeposited;

    bool public fundsWithdrawn;

    address public owner;
    address payable public fundsWallet; // Wallet address to receive ETH immediately

    // Define custom errors
    error NotOwner();
    error NotInFundingPeriod();
    error FundingPeriodNotEnded();
    error ClaimPeriodNotStarted();
    error AlreadyDeposited();
    error TransferFailed();
    error InvalidClaimPeriod();
    error InvalidFundingPeriod();
    error NoContributionsToClaim();
    error ClaimExceedsEffectiveAmount();

    event TokensDeposited(uint256 amount);
    event DepositReceived(address indexed user, uint256 amount, uint256 effectiveAmount);
    event TokensClaimed(address indexed user, uint256 amount);
    event BonusTokensClaimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier duringFunding() {
        if (block.timestamp < fundingStartTime || block.timestamp > fundingEndTime)
            revert NotInFundingPeriod();
        _;
    }

    modifier afterFunding() {
        if (block.timestamp <= fundingEndTime) revert FundingPeriodNotEnded();
        _;
    }

    modifier afterClaimStart() {
        if (block.timestamp < claimStartTime) revert ClaimPeriodNotStarted();
        _;
    }

    constructor(
        IERC20 _token,
        uint256 _fundingStartTime,
        uint256 _fundingEndTime,
        uint256 _claimStartTime,
        uint256 _totalTokensForSale,
        address payable _fundsWallet
    ) {
        if (_fundingEndTime <= _fundingStartTime) revert InvalidFundingPeriod();
        if (_claimStartTime < _fundingEndTime) revert InvalidClaimPeriod();
        if (_totalTokensForSale == 0) revert InvalidFundingPeriod();
        if (_fundsWallet == address(0)) revert TransferFailed();

        token = _token;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
        claimStartTime = _claimStartTime;
        vestingEndTime = claimStartTime + 30 days; // Vesting ends 1 month after claim start
        owner = msg.sender;
        fundsWallet = _fundsWallet;

        totalTokensForSale = _totalTokensForSale;

        // Initialize bonus thresholds and rates
        bonusRates = [40, 30, 15];
        bonusThresholds = [15 ether, 45 ether, 90 ether];
    }

    function depositTokens() external onlyOwner {
        if (tokensDeposited) revert AlreadyDeposited();
        if (!token.transferFrom(msg.sender, address(this), totalTokensForSale))
            revert TransferFailed();
        tokensDeposited = true;
        emit TokensDeposited(totalTokensForSale);
    }

    function contribute() public payable duringFunding nonReentrant {
        if (msg.value == 0) revert TransferFailed();

        uint256 remainingDeposit = msg.value;
        uint256 effectiveAmount = 0;

        uint256 totalEthAfter = totalEth;

        for (uint256 i = 0; i <= bonusThresholds.length; i++) {
            uint256 thresholdEnd = (i < bonusThresholds.length)
                ? bonusThresholds[i]
                : type(uint256).max;
            uint256 currentBonusRate = (i < bonusRates.length) ? bonusRates[i] : 0;

            if (totalEthAfter >= thresholdEnd) {
                continue;
            }

            uint256 remainingCapacity = thresholdEnd - totalEthAfter;

            if (remainingCapacity == 0) {
                continue;
            }

            uint256 amountInThisThreshold = remainingDeposit <= remainingCapacity
                ? remainingDeposit
                : remainingCapacity;

            if (amountInThisThreshold == 0) {
                continue;
            }

            // Calculate the bonus amount separately to prevent overflow
            uint256 bonusAmount = (amountInThisThreshold * currentBonusRate) / 100;
            effectiveAmount += amountInThisThreshold + bonusAmount;
            totalEthAfter += amountInThisThreshold;
            remainingDeposit -= amountInThisThreshold;

            if (remainingDeposit == 0) {
                break;
            }
        }

        // Handle any remaining deposit with no bonus
        if (remainingDeposit > 0) {
            effectiveAmount += remainingDeposit;
            totalEthAfter += remainingDeposit;
        }

        // Update total ETH collected and effective ETH
        totalEth += msg.value;
        totalEthEffective += effectiveAmount;

        // Update the user's contribution
        Contribution storage userContribution = contributions[msg.sender];
        userContribution.amount += msg.value;
        userContribution.effectiveAmount += effectiveAmount;

        // Calculate the new bonus tokens and update it
        userContribution.bonusTokens = userContribution.effectiveAmount - userContribution.amount;

        emit DepositReceived(msg.sender, msg.value, effectiveAmount);

        // Immediately transfer ETH to fundsWallet
        (bool success, ) = fundsWallet.call{value: msg.value}("");
        if (!success) revert TransferFailed();
    }

    function claim() external afterFunding afterClaimStart nonReentrant {
        Contribution storage userContribution = contributions[msg.sender];
        if (userContribution.amount == 0 && userContribution.effectiveAmount == 0)
            revert NoContributionsToClaim();

        // First-time claim: Transfer immediate tokens based on actual contribution
        if (!userContribution.claimed) {
            // The immediate tokens are calculated as the user's proportion of the total tokens
            uint256 immediateTokens = (userContribution.amount * totalTokensForSale) /
                totalEthEffective;

            // Mark the user as having claimed their immediate tokens
            userContribution.claimed = true;

            // Transfer the immediate tokens to the user
            if (!token.transfer(msg.sender, immediateTokens)) revert TransferFailed();

            emit TokensClaimed(msg.sender, immediateTokens);
        }

        // Handle bonus tokens that vest over time

        if (userContribution.bonusTokens > 0) {
            // Calculate the amount of bonus tokens that are vested up to the current time
            uint256 vestedAmount = _vestedBonusTokens();

            // Ensure the user can only claim the difference between vested tokens and already claimed bonus tokens
            uint256 claimableAmount = vestedAmount - userContribution.claimedBonusTokens;

            if (claimableAmount > 0) {
                // Update the user's claimed bonus tokens
                userContribution.claimedBonusTokens += claimableAmount;

                // Transfer the claimable vested bonus tokens to the user
                if (!token.transfer(msg.sender, claimableAmount)) revert TransferFailed();

                emit BonusTokensClaimed(msg.sender, claimableAmount);
            }
        }
    }

    function _vestedBonusTokens() internal view returns (uint256) {
        Contribution storage userContribution = contributions[msg.sender];

        if (block.timestamp >= vestingEndTime) {
            // All bonus tokens are vested at the end of the vesting period
            return userContribution.bonusTokens;
        } else if (block.timestamp < claimStartTime) {
            // Vesting hasn't started yet
            return 0;
        } else {
            // Calculate the vested amount based on the time elapsed since the claim start time
            uint256 vestingDuration = vestingEndTime - claimStartTime;
            uint256 timeElapsed = block.timestamp - claimStartTime;

            // Calculate the proportion of bonus tokens that are vested
            uint256 vestedAmount = (userContribution.bonusTokens * timeElapsed) / vestingDuration;
            return vestedAmount;
        }
    }

    // Fallback function to receive ETH
    receive() external payable {
        contribute();
    }
}

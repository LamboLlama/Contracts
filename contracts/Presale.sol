// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Presale is Ownable, ReentrancyGuard {
    struct Contribution {
        uint256 amount; // Actual ETH invested
        uint256 effectiveAmount; // Effective ETH after bonus
        uint256 claimedBonusTokens; // Bonus tokens already claimed
        bool claimed; // Whether immediate tokens have been claimed
    }

    // Custom errors for better gas efficiency
    error NotInFundingPeriod();
    error FundingPeriodNotEnded();
    error ClaimPeriodNotStarted();
    error AlreadyDeposited();
    error TransferFailed();
    error InvalidWhitelistPeriod();
    error InvalidFundingPeriod();
    error InvalidClaimPeriod();
    error NoContributionsToClaim();
    error ClaimExceedsEffectiveAmount();
    error NotWhitelisted();
    error WhitelistPeriodNotStarted();
    error WhitelistPeriodEnded();

    event TokensDeposited(uint256 amount);
    event DepositReceived(address indexed user, uint256 amount, uint256 effectiveAmount);
    event TokensClaimed(address indexed user, uint256 amount);
    event BonusTokensClaimed(address indexed user, uint256 amount);
    event AddressWhitelisted(address indexed user);
    event AddressRemovedFromWhitelist(address indexed user);

    uint256 public constant ONE_PERCENT = 10 ** 27;
    uint256 public constant ONE_HUNDRED_PERCENT = 100 * ONE_PERCENT;

    IERC20 public token;
    uint256 public fundingStartTime;
    uint256 public fundingEndTime;
    uint256 public claimStartTime;
    uint256 public vestingEndTime; // 1 month after claimStartTime
    uint256 public whitelistStartTime; // Start time for whitelist presale
    uint256 public whitelistEndTime; // End time for whitelist presale

    uint256 public totalEth; // Actual ETH deposited
    uint256 public totalEthEffective; // Effective ETH after bonus
    uint256 public totalTokensForSale;

    uint256[] public bonusRates;
    uint256[] public bonusThresholds;

    mapping(address => Contribution) public contributions;

    bool public tokensDeposited;
    bool public fundsWithdrawn;

    address public whitelistSigner; // Signer for whitelist presale
    address payable public fundsWallet; // Wallet address to receive ETH immediately

    modifier afterClaimStart() {
        if (block.timestamp <= claimStartTime) revert ClaimPeriodNotStarted();
        _;
    }

    constructor(
        IERC20 _token,
        uint256 _whitelistStartTime,
        uint256 _whitelistEndTime,
        uint256 _fundingStartTime,
        uint256 _fundingEndTime,
        uint256 _claimStartTime,
        uint256 _totalTokensForSale,
        address payable _fundsWallet,
        address _whitelistSigner
    ) {
        if (_whitelistEndTime < _whitelistStartTime) revert InvalidWhitelistPeriod();
        if (_fundingStartTime < _whitelistEndTime) revert InvalidWhitelistPeriod();
        if (_fundingEndTime < _fundingStartTime) revert InvalidFundingPeriod();
        if (_claimStartTime < _fundingEndTime) revert InvalidClaimPeriod();
        if (_totalTokensForSale == 0) revert InvalidFundingPeriod();
        if (_fundsWallet == address(0)) revert TransferFailed();

        token = _token;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
        claimStartTime = _claimStartTime;
        vestingEndTime = claimStartTime + 30 days; // Vesting ends 1 month after claim start
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;

        fundsWallet = _fundsWallet;
        whitelistSigner = _whitelistSigner;

        totalTokensForSale = _totalTokensForSale;

        // Initialize bonus thresholds and rates
        bonusRates = [40 * ONE_PERCENT, 30 * ONE_PERCENT, 15 * ONE_PERCENT, 0];
        bonusThresholds = [5 ether, 10 ether, 20 ether];
    }

    function depositTokens() external onlyOwner {
        if (tokensDeposited) revert AlreadyDeposited();
        token.transferFrom(msg.sender, address(this), totalTokensForSale);
        tokensDeposited = true;
        emit TokensDeposited(totalTokensForSale);
    }

    function isWhitelisted(bytes memory signature) external view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        return ECDSA.recover(ethSignedMessageHash, signature) == whitelistSigner;
    }

    function contribute(bytes memory signature) public payable nonReentrant {
        if (msg.value == 0) {
            revert TransferFailed();
        }

        if (block.timestamp >= whitelistStartTime && block.timestamp <= whitelistEndTime) {
            bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
            bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

            if (ECDSA.recover(ethSignedMessageHash, signature) != whitelistSigner) {
                revert NotWhitelisted();
            }
        } else if (block.timestamp < fundingStartTime || block.timestamp > fundingEndTime) {
            revert NotInFundingPeriod();
        }

        uint256 remainingDeposit = msg.value;
        uint256 effectiveAmount;
        uint256 totalEthAfter = totalEth;

        for (uint256 i = 0; i < bonusThresholds.length; i++) {
            uint256 currentThreshold = bonusThresholds[i];
            uint256 currentBonusRate = bonusRates[i];

            if (totalEthAfter >= currentThreshold) {
                continue; // Move to the next threshold if current is already reached
            }

            uint256 remainingCapacity = currentThreshold - totalEthAfter;

            uint256 amountInThisThreshold = remainingDeposit <= remainingCapacity
                ? remainingDeposit
                : remainingCapacity;

            uint256 bonusAmount = (amountInThisThreshold * currentBonusRate) / ONE_HUNDRED_PERCENT;
            effectiveAmount += amountInThisThreshold + bonusAmount;
            totalEthAfter += amountInThisThreshold;
            remainingDeposit -= amountInThisThreshold;

            if (remainingDeposit == 0) {
                break; // Stop the loop once the entire deposit has been allocated
            }
        }

        // For any remaining deposit beyond the highest threshold (20 ether), no bonus is applied
        if (remainingDeposit > 0) {
            effectiveAmount += remainingDeposit;
            totalEthAfter += remainingDeposit;
        }

        totalEth += msg.value;
        totalEthEffective += effectiveAmount;

        Contribution storage userContribution = contributions[msg.sender];

        userContribution.amount += msg.value;
        userContribution.effectiveAmount += effectiveAmount;

        emit DepositReceived(msg.sender, msg.value, effectiveAmount);

        (bool success, ) = fundsWallet.call{value: msg.value}("");
        if (!success) revert TransferFailed();
    }

    function claim() external afterClaimStart nonReentrant {
        Contribution storage userContribution = contributions[msg.sender];
        if (userContribution.amount == 0 && userContribution.effectiveAmount == 0)
            revert NoContributionsToClaim();

        if (!userContribution.claimed) {
            uint256 immediateTokens = (userContribution.amount * totalTokensForSale) /
                totalEthEffective;

            userContribution.claimed = true;

            token.transfer(msg.sender, immediateTokens);

            emit TokensClaimed(msg.sender, immediateTokens);
        }

        uint256 bonusTokens = userContribution.effectiveAmount - userContribution.amount;
        if (bonusTokens > 0) {
            uint256 vestedAmount = _vestedBonusTokens(bonusTokens);
            uint256 claimableAmount = vestedAmount - userContribution.claimedBonusTokens;

            if (claimableAmount > 0) {
                userContribution.claimedBonusTokens += claimableAmount;

                token.transfer(msg.sender, claimableAmount);

                emit BonusTokensClaimed(msg.sender, claimableAmount);
            }
        }
    }

    function _vestedBonusTokens(uint256 bonusTokens) internal view returns (uint256) {
        if (block.timestamp >= vestingEndTime) {
            return bonusTokens;
        } else {
            uint256 vestingDuration = vestingEndTime - claimStartTime;
            uint256 timeElapsed = block.timestamp - claimStartTime;

            return (bonusTokens * timeElapsed) / vestingDuration;
        }
    }

    receive() external payable {
        contribute("");
    }
}

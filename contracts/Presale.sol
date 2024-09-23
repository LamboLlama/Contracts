// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Presale is Ownable, ReentrancyGuard {
    struct Contribution {
        uint amount; // Actual ETH invested
        uint effectiveAmount; // Effective ETH after bonus
        uint claimedBonusTokens; // Bonus tokens already claimed
        bool claimed; // Whether immediate tokens have been claimed
    }

    // Define custom errors
    error NotInFundingPeriod();
    error FundingPeriodNotEnded();
    error ClaimPeriodNotStarted();
    error AlreadyDeposited();
    error TransferFailed();
    error InvalidWHitelistPeriod();
    error InvalidFundingPeriod();
    error InvalidClaimPeriod();
    error NoContributionsToClaim();
    error ClaimExceedsEffectiveAmount();
    error NotWhitelisted();
    error WhitelistPeriodNotStarted();
    error WhitelistPeriodEnded();

    event TokensDeposited(uint amount);
    event DepositReceived(address indexed user, uint amount, uint effectiveAmount);
    event TokensClaimed(address indexed user, uint amount);
    event BonusTokensClaimed(address indexed user, uint amount);
    event AddressWhitelisted(address indexed user);
    event AddressRemovedFromWhitelist(address indexed user);

    uint public constant ONE_PERCENT = 10 ** 27;
    uint public constant ONE_HUNDRED_PERCENT = 100 * ONE_PERCENT;

    IERC20 public token;
    uint public fundingStartTime;
    uint public fundingEndTime;

    uint public claimStartTime;
    uint public vestingEndTime; // 1 month after claimStartTime

    uint public whitelistStartTime; // Start time for whitelist presale
    uint public whitelistEndTime; // End time for whitelist presale

    uint public totalEth; // Actual ETH deposited
    uint public totalEthEffective; // Effective ETH after bonus
    uint public totalTokensForSale;

    uint[] public bonusRates;
    uint[] public bonusThresholds;

    mapping(address => Contribution) public contributions;
    mapping(address => bool) public whitelist; // Whitelist mapping

    bool public tokensDeposited;
    bool public fundsWithdrawn;

    address payable public fundsWallet; // Wallet address to receive ETH immediately

    modifier afterClaimStart() {
        if (block.timestamp <= claimStartTime) revert ClaimPeriodNotStarted();
        _;
    }

    constructor(
        IERC20 _token,
        uint _whitelistStartTime,
        uint _whitelistEndTime,
        uint _fundingStartTime,
        uint _fundingEndTime,
        uint _claimStartTime,
        uint _totalTokensForSale,
        address payable _fundsWallet
    ) {
        if (_whitelistEndTime <= _whitelistStartTime) revert InvalidWHitelistPeriod();
        if (_fundingStartTime <= _whitelistEndTime) revert InvalidWHitelistPeriod();
        if (_fundingEndTime <= _fundingStartTime) revert InvalidFundingPeriod();
        if (_claimStartTime <= _fundingEndTime) revert InvalidClaimPeriod();
        if (_totalTokensForSale == 0) revert InvalidFundingPeriod();
        if (_fundsWallet == address(0)) revert TransferFailed();

        token = _token;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
        claimStartTime = _claimStartTime;
        vestingEndTime = claimStartTime + 30 days; // Vesting ends 1 month after claim start
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime; // Set whitelist period duration
        fundsWallet = _fundsWallet;

        totalTokensForSale = _totalTokensForSale;

        // Initialize bonus thresholds and rates
        bonusRates = [40 * ONE_PERCENT, 30 * ONE_PERCENT, 15 * ONE_PERCENT, 0];
        bonusThresholds = [15 ether, 45 ether, 90 ether, type(uint).max];
    }

    function depositTokens() external onlyOwner {
        if (tokensDeposited) revert AlreadyDeposited();
        token.transferFrom(msg.sender, address(this), totalTokensForSale);
        tokensDeposited = true;
        emit TokensDeposited(totalTokensForSale);
    }

    function whitelistAddresses(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = true;
            emit AddressWhitelisted(_users[i]);
        }
    }

    function removeWhitelistAddresses(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = false;
            emit AddressRemovedFromWhitelist(_users[i]);
        }
    }

    function contribute() public payable nonReentrant {
        if (msg.value == 0) revert TransferFailed();

        // Check if the contribution is within the whitelist period or public period
        // Check if we are in the whitelist period
        if (block.timestamp >= whitelistStartTime && block.timestamp <= whitelistEndTime) {
            // During whitelist period, only whitelisted addresses can contribute
            if (!whitelist[msg.sender]) revert NotWhitelisted();
        } else if (block.timestamp < fundingStartTime || block.timestamp > fundingEndTime) {
            // Not within the public presale period, so throw error
            revert NotInFundingPeriod();
        }

        uint remainingDeposit = msg.value;
        uint effectiveAmount;
        uint totalEthAfter = totalEth;

        for (uint i = 0; i < bonusThresholds.length; i++) {
            uint currentTreshold = bonusThresholds[i];
            uint currentBonusRate = bonusRates[i];

            if (totalEthAfter >= currentTreshold) {
                continue;
            }

            uint remainingCapacity = currentTreshold - totalEthAfter;

            uint amountInThisThreshold = remainingDeposit <= remainingCapacity
                ? remainingDeposit
                : remainingCapacity;

            uint bonusAmount = (amountInThisThreshold * currentBonusRate) / ONE_HUNDRED_PERCENT;
            effectiveAmount += amountInThisThreshold + bonusAmount;
            totalEthAfter += amountInThisThreshold;
            remainingDeposit -= amountInThisThreshold;

            if (remainingDeposit == 0) {
                break;
            }
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
            uint immediateTokens = (userContribution.amount * totalTokensForSale) /
                totalEthEffective;

            userContribution.claimed = true;

            token.transfer(msg.sender, immediateTokens);

            emit TokensClaimed(msg.sender, immediateTokens);
        }

        uint bonusTokens = userContribution.effectiveAmount - userContribution.amount;
        if (bonusTokens > 0) {
            uint vestedAmount = _vestedBonusTokens(bonusTokens);
            uint claimableAmount = vestedAmount - userContribution.claimedBonusTokens;

            if (claimableAmount > 0) {
                userContribution.claimedBonusTokens += claimableAmount;

                token.transfer(msg.sender, claimableAmount);

                emit BonusTokensClaimed(msg.sender, claimableAmount);
            }
        }
    }

    function _vestedBonusTokens(uint bonusTokens) internal view returns (uint) {
        if (block.timestamp >= vestingEndTime) {
            return bonusTokens;
        } else {
            uint vestingDuration = vestingEndTime - claimStartTime;
            uint timeElapsed = block.timestamp - claimStartTime;

            uint vestedAmount = (bonusTokens * timeElapsed) / vestingDuration;
            return vestedAmount;
        }
    }

    receive() external payable {
        contribute();
    }
}

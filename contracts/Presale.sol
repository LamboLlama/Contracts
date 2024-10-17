// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Presale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Contribution {
        uint256 amount; // Actual ETH invested
        uint256 effectiveAmount; // Effective ETH after bonus
        uint256 claimedBonusTokens; // Bonus tokens already claimed
        bool claimed; // Whether immediate tokens have been claimed
    }

    // Custom errors for better gas efficiency
    error NoValue();

    error TransferFailed();
    error AlreadyDeposited();

    error InvalidWalletInput();
    error InvalidPresaleClaimInput();
    error InvalidPresaleInput();
    error InvalidWhitelistInput();

    error NotWhitelisted();
    error ClaimPeriodNotStarted();
    error NoContributionsToClaim();
    error NotInContributionPeriod();

    event TokensDeposited(uint256 amount);
    event ContributionReceived(address indexed user, uint256 amount, uint256 effectiveAmount);
    event TokensClaimed(address indexed user, uint256 amount);
    event BonusTokensClaimed(address indexed user, uint256 amount);

    uint256 public constant ONE_PERCENT = 10 ** 27;
    uint256 public constant ONE_HUNDRED_PERCENT = 100 * ONE_PERCENT;

    IERC20 public immutable token;

    bool public tokensDeposited;

    uint256 public presaleSupply;

    uint256 public totalEth;
    uint256 public totalEthEffective;

    uint256 public whitelistStartTime;
    uint256 public whitelistEndTime;

    uint256 public publicPresaleStartTime;
    uint256 public publicPresaleEndTime;

    uint256 public presaleClaimStartTime;
    uint256 public presaleVestingEndTime;

    uint256[] public bonusRates;
    uint256[] public bonusThresholds;

    mapping(address => Contribution) public contributions;

    address public whitelistSigner; // Signer for whitelist presale
    address payable public treasuryWallet; // Wallet address to receive ETH immediately

    modifier afterClaimStart() {
        if (block.timestamp <= presaleClaimStartTime) revert ClaimPeriodNotStarted();
        _;
    }

    constructor(
        IERC20 _token,
        uint256 _presaleSupply,
        address _whitelistSigner,
        address payable _treasuryWallet,
        uint256 _whitelistStartTime,
        uint256 _whitelistEndTime,
        uint256 _publicPresaleStartTime,
        uint256 _publicPresaleEndTime,
        uint256 _presaleClaimStartTime
    ) {
        if (_presaleSupply == 0 || _presaleSupply < 1000 ether) revert InvalidPresaleInput();
        if (_treasuryWallet == address(0)) revert InvalidWalletInput();

        if (_whitelistEndTime < _whitelistStartTime) revert InvalidWhitelistInput();
        if (_publicPresaleStartTime < _whitelistEndTime) revert InvalidWhitelistInput();
        if (_publicPresaleEndTime < _publicPresaleStartTime) revert InvalidPresaleInput();
        if (_presaleClaimStartTime < _publicPresaleEndTime) revert InvalidPresaleClaimInput();

        token = _token;
        publicPresaleStartTime = _publicPresaleStartTime;
        publicPresaleEndTime = _publicPresaleEndTime;
        presaleClaimStartTime = _presaleClaimStartTime;
        presaleVestingEndTime = presaleClaimStartTime + 30 days; // Vesting ends 1 month after claim start
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;

        treasuryWallet = _treasuryWallet;
        whitelistSigner = _whitelistSigner;

        presaleSupply = _presaleSupply;

        // Initialize bonus thresholds and rates
        bonusRates = [40 * ONE_PERCENT, 30 * ONE_PERCENT, 15 * ONE_PERCENT, 0];
        bonusThresholds = [5 ether, 10 ether, 20 ether];
    }

    function depositTokens() external onlyOwner {
        if (tokensDeposited) revert AlreadyDeposited();
        token.transferFrom(msg.sender, address(this), presaleSupply);
        tokensDeposited = true;
        emit TokensDeposited(presaleSupply);
    }

    function isWhitelisted(bytes memory signature) external view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        return ECDSA.recover(ethSignedMessageHash, signature) == whitelistSigner;
    }

    function contribute(bytes memory signature) public payable nonReentrant {
        if (msg.value == 0) {
            revert NoValue();
        }

        if (block.timestamp < whitelistStartTime || block.timestamp > publicPresaleEndTime) {
            revert NotInContributionPeriod();
        }

        if (block.timestamp <= whitelistEndTime) {
            if (signature.length == 0) {
                revert NotWhitelisted();
            }

            bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
            bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

            if (ECDSA.recover(ethSignedMessageHash, signature) != whitelistSigner) {
                revert NotWhitelisted();
            }
        }

        uint256 remainingDeposit = msg.value;
        uint256 effectiveAmount;

        // Apply bonus for the first threshold (up to 5 ETH)
        if (totalEth < bonusThresholds[0]) {
            uint256 thresholdAmount = bonusThresholds[0] - totalEth;
            uint256 amountInThisThreshold = remainingDeposit <= thresholdAmount
                ? remainingDeposit
                : thresholdAmount;
            uint256 bonusAmount = (amountInThisThreshold * bonusRates[0]) / ONE_HUNDRED_PERCENT;
            effectiveAmount += amountInThisThreshold + bonusAmount;
            remainingDeposit -= amountInThisThreshold;
            totalEth += amountInThisThreshold;
        }

        // Apply bonus for the second threshold (between 5 ETH and 10 ETH)
        if (
            remainingDeposit > 0 && totalEth >= bonusThresholds[0] && totalEth < bonusThresholds[1]
        ) {
            uint256 thresholdAmount = bonusThresholds[1] - totalEth;
            uint256 amountInThisThreshold = remainingDeposit <= thresholdAmount
                ? remainingDeposit
                : thresholdAmount;
            uint256 bonusAmount = (amountInThisThreshold * bonusRates[1]) / ONE_HUNDRED_PERCENT;
            effectiveAmount += amountInThisThreshold + bonusAmount;
            remainingDeposit -= amountInThisThreshold;
            totalEth += amountInThisThreshold;
        }

        // Apply bonus for the third threshold (between 10 ETH and 20 ETH)
        if (
            remainingDeposit > 0 && totalEth >= bonusThresholds[1] && totalEth < bonusThresholds[2]
        ) {
            uint256 thresholdAmount = bonusThresholds[2] - totalEth;
            uint256 amountInThisThreshold = remainingDeposit <= thresholdAmount
                ? remainingDeposit
                : thresholdAmount;
            uint256 bonusAmount = (amountInThisThreshold * bonusRates[2]) / ONE_HUNDRED_PERCENT;
            effectiveAmount += amountInThisThreshold + bonusAmount;
            remainingDeposit -= amountInThisThreshold;
            totalEth += amountInThisThreshold;
        }

        // Apply no bonus for deposits exceeding 20 ETH
        if (remainingDeposit > 0) {
            effectiveAmount += remainingDeposit;
            totalEth += remainingDeposit;
        }

        totalEthEffective += effectiveAmount;

        Contribution storage userContribution = contributions[msg.sender];
        userContribution.amount += msg.value;
        userContribution.effectiveAmount += effectiveAmount;

        (bool success, ) = treasuryWallet.call{value: msg.value}("");

        if (!success) {
            revert TransferFailed();
        }

        emit ContributionReceived(msg.sender, msg.value, effectiveAmount);
    }

    function claim() external afterClaimStart nonReentrant {
        Contribution storage userContribution = contributions[msg.sender];
        if (userContribution.amount == 0 && userContribution.effectiveAmount == 0)
            revert NoContributionsToClaim();

        if (!userContribution.claimed) {
            uint256 immediateTokens = userContribution.amount.mul(presaleSupply).div(
                totalEthEffective
            );

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
        if (block.timestamp >= presaleVestingEndTime) {
            return bonusTokens;
        } else {
            uint256 vestingDuration = presaleVestingEndTime - presaleClaimStartTime;
            uint256 timeElapsed = block.timestamp - presaleClaimStartTime;

            return bonusTokens.mul(timeElapsed).div(vestingDuration);
        }
    }

    receive() external payable {
        contribute("");
    }
}

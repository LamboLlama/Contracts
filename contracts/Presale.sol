// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Importing necessary OpenZeppelin contracts and libraries
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For signature verification
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // ERC20 interface
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; // Provides basic access control
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Protects against reentrancy attacks

/**
 * @title Presale Contract
 * @dev This contract manages a token presale with bonus thresholds and vesting for bonus tokens.
 * Users can contribute ETH during the presale period and claim their tokens after the claim period starts.
 * The contract supports a whitelist for early contributions and applies bonuses based on contribution thresholds.
 */
contract Presale is Ownable, ReentrancyGuard {
    /// @dev Structure to store each contributor's information
    struct Contribution {
        uint256 amount; // Actual ETH invested by the user
        uint256 effectiveAmount; // Effective ETH after applying bonuses
        uint256 claimedBonusTokens; // Bonus tokens already claimed by the user
        bool claimed; // Whether the user has claimed their initial tokens
    }

    // Custom errors for more gas-efficient error handling

    error TransferFailed(); // Thrown when ETH transfer to treasury wallet fails
    error LowContribution(); // Thrown when ETH sent does not meet the minimum contribution
    error AlreadyDeposited(); // Thrown when tokens have already been deposited
    error InvalidWalletInput(); // Thrown when an invalid wallet address is provided
    error InvalidPresaleClaimInput(); // Thrown when presale claim time is invalid
    error InvalidPresaleInput(); // Thrown when presale parameters are invalid
    error InvalidWhitelistInput(); // Thrown when whitelist parameters are invalid
    error NotWhitelisted(); // Thrown when a user is not whitelisted
    error ClaimPeriodNotStarted(); // Thrown when claim period hasn't started yet
    error NoContributionsToClaim(); // Thrown when a user has no contributions to claim
    error NotInContributionPeriod(); // Thrown when contributions are made outside the allowed period

    /// @notice Emitted when tokens are deposited into the contract
    /// @param amount The amount of tokens deposited
    event TokensDeposited(uint256 amount);

    /// @notice Emitted when a user makes a contribution
    /// @param user The address of the contributor
    /// @param amount The amount of ETH contributed
    /// @param effectiveAmount The effective amount after applying bonuses
    event ContributionReceived(address indexed user, uint256 amount, uint256 effectiveAmount);

    /// @notice Emitted when a user claims their initial tokens
    /// @param user The address of the user
    /// @param amount The amount of tokens claimed
    event TokensClaimed(address indexed user, uint256 amount);

    /// @notice Emitted when a user claims their bonus tokens
    /// @param user The address of the user
    /// @param amount The amount of bonus tokens claimed
    event BonusTokensClaimed(address indexed user, uint256 amount);

    // Constants for percentage calculations
    uint256 private constant ONE_PERCENT = 10 ** 27; // Represents 1% in fixed-point arithmetic
    uint256 private constant ONE_HUNDRED_PERCENT = 100 * ONE_PERCENT; // Represents 100%

    /// @notice The ERC20 token being sold
    IERC20 public token;

    /// @notice Indicates whether tokens have been deposited into the contract
    bool public tokensDeposited;

    /// @notice Total number of tokens allocated for the presale
    uint256 public presaleSupply;

    /// @notice Total actual ETH collected from contributors
    uint256 public totalEth;

    /// @notice Total effective ETH after applying bonuses
    uint256 public totalEthEffective;

    /// @notice Start time for the whitelist contribution period
    uint256 public whitelistStartTime;

    /// @notice End time for the whitelist contribution period
    uint256 public whitelistEndTime;

    /// @notice Start time for the public presale
    uint256 public publicPresaleStartTime;

    /// @notice End time for the public presale
    uint256 public publicPresaleEndTime;

    /// @notice Start time when token claims can begin
    uint256 public presaleClaimStartTime;

    /// @notice End time for the vesting period of bonus tokens
    uint256 public presaleVestingEndTime;

    /// @notice Array of bonus rates corresponding to thresholds
    uint256[] public bonusRates;

    /// @notice Array of ETH thresholds for bonus rates
    uint256[] public bonusThresholds;

    /// @notice Mapping of contributions by user address
    mapping(address => Contribution) public contributions;

    /// @notice Address of the treasury wallet where collected ETH is sent
    address public treasuryWallet;

    /// @notice Address of the signer for whitelist verification
    address public whitelistSigner;

    /// @dev Modifier to ensure the function is called after the claim period has started
    modifier afterClaimStart() {
        if (block.timestamp <= presaleClaimStartTime) revert ClaimPeriodNotStarted();
        _;
    }

    /**
     * @notice Constructor to initialize the presale contract
     * @param _token The ERC20 token being sold
     * @param _presaleSupply The total number of tokens allocated for the presale
     * @param _whitelistSigner The address of the whitelist signer
     * @param _treasuryWallet The address of the treasury wallet to receive ETH
     * @param _whitelistStartTime The start time for the whitelist contribution period
     * @param _whitelistEndTime The end time for the whitelist contribution period
     * @param _publicPresaleStartTime The start time for the public presale
     * @param _publicPresaleEndTime The end time for the public presale
     * @param _presaleClaimStartTime The start time when token claims can begin
     */
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
        // Validate treasury wallet address
        if (_treasuryWallet == address(0)) revert InvalidWalletInput();

        // Validate whitelist and presale times
        if (_whitelistEndTime < _whitelistStartTime) revert InvalidWhitelistInput();
        if (_publicPresaleStartTime < _whitelistEndTime) revert InvalidWhitelistInput();
        if (_publicPresaleEndTime < _publicPresaleStartTime) revert InvalidPresaleInput();
        if (_presaleClaimStartTime < _publicPresaleEndTime) revert InvalidPresaleClaimInput();

        // Initialize state variables
        token = _token;
        publicPresaleStartTime = _publicPresaleStartTime;
        publicPresaleEndTime = _publicPresaleEndTime;
        presaleClaimStartTime = _presaleClaimStartTime;
        presaleVestingEndTime = presaleClaimStartTime + 30 days; // Vesting ends 30 days after claim start
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;

        treasuryWallet = _treasuryWallet;
        whitelistSigner = _whitelistSigner;

        presaleSupply = _presaleSupply;

        // Initialize bonus thresholds and rates
        bonusRates = [
            uint256(40) * ONE_PERCENT, // 40% bonus rate
            uint256(30) * ONE_PERCENT, // 30% bonus rate
            uint256(15) * ONE_PERCENT, // 15% bonus rate
            0 // 0% bonus rate beyond thresholds
        ];
        bonusThresholds = [5 ether, 10 ether, 20 ether]; // Bonus thresholds at 5 ETH, 10 ETH, and 20 ETH
    }

    /**
     * @notice Allows the owner to deposit tokens into the contract for the presale
     */
    function depositTokens() external onlyOwner {
        if (tokensDeposited) revert AlreadyDeposited();
        token.transferFrom(msg.sender, address(this), presaleSupply);
        tokensDeposited = true;
        emit TokensDeposited(presaleSupply);
    }

    /**
     * @notice Checks if an address is whitelisted
     * @param signature The signature provided by the user
     * @return bool indicating whether the user is whitelisted
     */
    function isWhitelisted(bytes memory signature) public view returns (bool) {
        // Recreate the signed message hash
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        // Verify the signature
        return ECDSA.recover(ethSignedMessageHash, signature) == whitelistSigner;
    }

    /**
     * @notice Allows users to contribute ETH during the presale period
     * @param signature The signature for whitelist verification during the whitelist period
     */
    function contribute(bytes memory signature) public payable nonReentrant {
        if (msg.value == 0) {
            revert LowContribution(); // Ensure no dust eth is sent
        }

        // Check if contribution is within allowed time frames
        if (block.timestamp < whitelistStartTime || block.timestamp > publicPresaleEndTime) {
            revert NotInContributionPeriod();
        }

        // If within whitelist period, verify signature
        if (block.timestamp <= whitelistEndTime) {
            if (!isWhitelisted(signature)) {
                revert NotWhitelisted();
            }
        }

        uint256 remainingDeposit = msg.value; // Remaining ETH to process
        uint256 effectiveAmount = 0; // Total effective amount after bonuses

        // Iterate through bonus thresholds and apply bonuses
        for (uint256 i = 0; i < bonusThresholds.length; i++) {
            if (remainingDeposit == 0 || totalEth >= bonusThresholds[i]) {
                // If no remaining ETH to process or we've exceeded the threshold, break
                continue;
            }

            uint256 thresholdAmount = bonusThresholds[i] - totalEth;
            uint256 amountInThisThreshold = remainingDeposit <= thresholdAmount
                ? remainingDeposit
                : thresholdAmount; // Calculate how much ETH can be processed in this threshold
            uint256 bonusAmount = (amountInThisThreshold * bonusRates[i]) / ONE_HUNDRED_PERCENT; // Calculate bonus

            effectiveAmount += amountInThisThreshold + bonusAmount; // Update effective amount
            remainingDeposit -= amountInThisThreshold; // Update remaining deposit
            totalEth += amountInThisThreshold; // Update total ETH collected
        }

        // Any remaining deposit beyond thresholds gets no bonus
        if (remainingDeposit > 0) {
            effectiveAmount += remainingDeposit; // Add remaining deposit to effective amount
            totalEth += remainingDeposit; // Update total ETH collected
        }

        totalEthEffective += effectiveAmount; // Update total effective ETH

        // Update user's contribution
        Contribution storage userContribution = contributions[msg.sender];
        userContribution.amount += msg.value; // Update actual amount contributed
        userContribution.effectiveAmount += effectiveAmount; // Update effective amount

        // Transfer the contributed ETH to the treasury wallet
        (bool success, ) = treasuryWallet.call{value: msg.value}("");
        if (!success) {
            revert TransferFailed(); // Revert if transfer fails
        }

        emit ContributionReceived(msg.sender, msg.value, effectiveAmount); // Emit event
    }

    /**
     * @notice Allows users to claim their tokens after the claim period has started
     */
    function claim() external afterClaimStart nonReentrant {
        Contribution storage userContribution = contributions[msg.sender];
        if (userContribution.amount == 0 && userContribution.effectiveAmount == 0)
            revert NoContributionsToClaim(); // Ensure the user has contributions to claim

        // Claim initial tokens if not already claimed
        if (!userContribution.claimed) {
            // Calculate the amount of tokens to distribute immediately
            uint256 userAmountTokens = (userContribution.amount * presaleSupply) /
                totalEthEffective;

            userContribution.claimed = true; // Mark as claimed

            token.transfer(msg.sender, userAmountTokens); // Transfer tokens to the user

            emit TokensClaimed(msg.sender, userAmountTokens); // Emit event
        }

        // Calculate bonus tokens
        uint256 bonusAmountEth = userContribution.effectiveAmount - userContribution.amount;

        if (bonusAmountEth > 0) {
            // Calculate vested bonus tokens
            uint256 vestedTokens = _vestedBonusTokens(bonusAmountEth);
            // Calculate claimable amount (vested amount minus already claimed)
            uint256 claimableTokens = vestedTokens - userContribution.claimedBonusTokens;

            if (claimableTokens > 0) {
                // Update user's claimed bonus tokens
                userContribution.claimedBonusTokens +=
                    claimableTokens;

                token.transfer(msg.sender, claimableTokens); // Transfer bonus tokens to the user

                emit BonusTokensClaimed(msg.sender, claimableTokens); // Emit event
            }
        }
    }

    /**
     * @dev Internal function to calculate the number of vested bonus tokens for a user
     * @param bonusAmountEth The bonus ETH amount contributed by the user
     * @return The amount of bonus tokens that have vested
     */
    function _vestedBonusTokens(uint256 bonusAmountEth) internal view returns (uint256) {
        uint256 bonusAmountTokens = (bonusAmountEth * presaleSupply) / totalEthEffective;

        if (block.timestamp >= presaleVestingEndTime) {
            // All bonus tokens have vested
            return bonusAmountTokens;
        } else {
            uint256 vestingDuration = presaleVestingEndTime - presaleClaimStartTime; // Total vesting duration
            uint256 timeElapsed = block.timestamp - presaleClaimStartTime; // Time elapsed since claim start

            // Calculate vested amount proportionally
            return bonusAmountTokens * timeElapsed / vestingDuration;
        }
    }

    /**
     * @notice Fallback function to receive ETH contributions
     * Users can send ETH directly to the contract address to participate in the presale
     */
    receive() external payable {
        contribute(""); // Calls the contribute function without a signature (for public presale)
    }
}

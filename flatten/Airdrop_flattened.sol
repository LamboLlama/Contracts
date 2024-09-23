

// Sources flattened with hardhat v2.22.5 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// File contracts/Airdrop.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.22;


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

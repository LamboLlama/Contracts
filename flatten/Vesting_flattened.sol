

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


// File contracts/Vesting.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.22;


contract Vesting is Ownable {
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 start;
        uint256 duration;
    }

    bool public configuratedAndFixed;
    IERC20 public token;
    mapping(address => VestingSchedule) public vestingSchedules;

    event TokensClaimed(address indexed beneficiary, uint256 amount);

    // Custom Errors
    error ZeroTokenAddress();
    error ZeroBeneficiaryAddress();
    error ZeroTotalAmount();
    error ZeroDuration();
    error VestingNotStarted();
    error NoTokensToClaim();
    error ContractFixed();
    error WithdrawVestingTokenNotAllowed();

    constructor(IERC20 token_) {
        if (address(token_) == address(0)) revert ZeroTokenAddress();
        token = token_;
    }

    modifier onlyBeforeConfiguratedAndFixed() {
        if (configuratedAndFixed) revert ContractFixed();
        _;
    }

    function fix() external onlyOwner {
        configuratedAndFixed = true;
    }

    function withdraw() external onlyOwner onlyBeforeConfiguratedAndFixed {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdrawStuckERC20(IERC20 token_) external onlyOwner {
        if (address(token_) == address(token)) revert WithdrawVestingTokenNotAllowed();
        token_.transfer(msg.sender, token_.balanceOf(address(this)));
    }

    function setVestingSchedule(
        address beneficiary_,
        uint256 totalAmount_,
        uint256 start_,
        uint256 duration_
    ) external onlyOwner onlyBeforeConfiguratedAndFixed {
        if (beneficiary_ == address(0)) revert ZeroBeneficiaryAddress();
        if (totalAmount_ == 0) revert ZeroTotalAmount();
        if (duration_ == 0) revert ZeroDuration();

        vestingSchedules[beneficiary_] = VestingSchedule({
            totalAmount: totalAmount_,
            claimedAmount: 0,
            start: start_,
            duration: duration_
        });
    }

    function claimTokens() external {
        VestingSchedule storage schedule_ = vestingSchedules[msg.sender];

        if (block.timestamp <= schedule_.start) revert VestingNotStarted();

        uint256 elapsedTime_ = block.timestamp - schedule_.start;

        if (elapsedTime_ > schedule_.duration) {
            elapsedTime_ = schedule_.duration;
        }

        uint256 vestedAmount_ = (schedule_.totalAmount * elapsedTime_) / schedule_.duration;
        uint256 claimableAmount_ = vestedAmount_ - schedule_.claimedAmount;

        if (claimableAmount_ == 0) revert NoTokensToClaim();

        schedule_.claimedAmount += claimableAmount_;
        token.transfer(msg.sender, claimableAmount_);

        emit TokensClaimed(msg.sender, claimableAmount_);
    }

    function getClaimableAmount(address beneficiary_) external view returns (uint256) {
        VestingSchedule storage schedule_ = vestingSchedules[beneficiary_];

        if (block.timestamp <= schedule_.start) {
            return 0;
        }

        uint256 elapsedTime_ = block.timestamp - schedule_.start;
        if (elapsedTime_ > schedule_.duration) {
            elapsedTime_ = schedule_.duration;
        }

        uint256 vestedAmount_ = (schedule_.totalAmount * elapsedTime_) / schedule_.duration;

        return vestedAmount_ - schedule_.claimedAmount;
    }
}

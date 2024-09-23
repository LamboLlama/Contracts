// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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

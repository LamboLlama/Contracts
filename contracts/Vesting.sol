// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable {
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 start;
        uint256 duration;
    }

    bool public configuratedAndFixed;
    IERC20 public immutable token;
    mapping(address => VestingSchedule) public vestingSchedules;

    event TokensClaimed(address indexed beneficiary, uint256 amount);

    constructor(IERC20 token_) {
        require(address(token_) != address(0), "Vesting: zero token address");
        token = token_;
    }

    modifier onlyBeforeConfiguratedAndFixed() {
        require(!configuratedAndFixed, "Vesting: not available after the contract is fixed");
        _;
    }

    function fix() external onlyOwner {
        configuratedAndFixed = true;
    }

    function withdraw() external onlyOwner onlyBeforeConfiguratedAndFixed {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setVestingSchedule(
        address beneficiary_,
        uint256 totalAmount_,
        uint256 start_,
        uint256 duration_
    ) external onlyOwner onlyBeforeConfiguratedAndFixed {
        require(beneficiary_ != address(0), "Vesting: zero beneficiary address");
        require(totalAmount_ > 0, "Vesting: zero total amount");
        require(duration_ > 0, "Vesting: zero duration");

        vestingSchedules[beneficiary_] = VestingSchedule({
            totalAmount: totalAmount_,
            claimedAmount: 0,
            start: start_,
            duration: duration_
        });
    }

    function claimTokens() external {
        VestingSchedule storage schedule_ = vestingSchedules[msg.sender];

        require(block.timestamp > schedule_.start, "Vesting: vesting not started");

        uint256 elapsedTime_ = block.timestamp - schedule_.start;

        if (elapsedTime_ > schedule_.duration) {
            elapsedTime_ = schedule_.duration;
        }

        uint256 vestedAmount_ = (schedule_.totalAmount * elapsedTime_) / schedule_.duration;
        uint256 claimableAmount_ = vestedAmount_ - schedule_.claimedAmount;

        require(claimableAmount_ > 0, "Vesting: no tokens to claim");

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

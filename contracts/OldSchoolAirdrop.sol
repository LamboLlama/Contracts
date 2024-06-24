// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OldSchoolAirdrop is Ownable {
    IERC20 public immutable token;
    mapping(address => uint256) public claimableTokens;
    uint256 public totalClaimable;
    uint256 public immutable claimPeriodStart;
    uint256 public immutable claimPeriodEnd;

    event HasClaimed(address indexed recipient, uint256 amount);

    constructor(
        IERC20 token_,
        address owner_,
        uint256 claimPeriodStart_,
        uint256 claimPeriodEnd_
    ) Ownable() {
        require(address(token_) != address(0), "OldSchoolAirdrop: zero token address");
        require(owner_ != address(0), "OldSchoolAirdrop: zero owner address");
        require(
            claimPeriodStart_ > block.timestamp,
            "OldSchoolAirdrop: start should be in the future"
        );
        require(
            claimPeriodEnd_ > claimPeriodStart_,
            "OldSchoolAirdrop: start should be before end"
        );

        token = token_;
        claimPeriodStart = claimPeriodStart_;
        claimPeriodEnd = claimPeriodEnd_;
        _transferOwnership(owner_);
    }

    function setRecipients(
        address[] calldata recipients_,
        uint256[] calldata claimableAmount_
    ) external onlyOwner {
        require(
            recipients_.length == claimableAmount_.length,
            "OldSchoolAirdrop: invalid array length"
        );
        uint256 sum = totalClaimable;
        for (uint256 i = 0; i < recipients_.length; i++) {
            require(
                claimableTokens[recipients_[i]] == 0,
                "OldSchoolAirdrop: recipient already set"
            );
            claimableTokens[recipients_[i]] = claimableAmount_[i];
            unchecked {
                sum += claimableAmount_[i];
            }
        }

        totalClaimable = sum;
    }

    function claim() public {
        require(block.timestamp >= claimPeriodStart, "OldSchoolAirdrop: claim not started");
        require(block.timestamp < claimPeriodEnd, "OldSchoolAirdrop: claim ended");

        uint256 amount = claimableTokens[msg.sender];
        require(amount > 0, "OldSchoolAirdrop: nothing to claim");

        claimableTokens[msg.sender] = 0;

        token.transfer(msg.sender, amount);
        emit HasClaimed(msg.sender, amount);
    }

    function withdraw(IERC20 token_, uint256 amount_) external onlyOwner {
        IERC20(token_).transfer(msg.sender, amount_);
    }
}

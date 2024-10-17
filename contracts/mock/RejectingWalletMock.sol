// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

contract RejectingWalletMock {
    fallback() external payable {
        revert("Transfer rejected");
    }
}

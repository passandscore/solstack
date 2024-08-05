// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract RevertingRecipient {
    receive() external payable {
        revert();
    }
}

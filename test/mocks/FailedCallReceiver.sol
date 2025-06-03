// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FailedCallReceiver {
    fallback() external {
        revert("FailedCall");
    }
}

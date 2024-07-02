// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {MockERC20} from "src/mocks/MockERC20.sol";
import "forge-std-1.8.2/Test.sol";

abstract contract ContractUnderTest is Test {
    MockERC20 internal contractUnderTest;
    uint256 internal constant TOTAL_SUPPLY = 1000000 * 10**18;

    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));

    function setUp() public virtual {
        vm.startPrank({msgSender: deployer});
        contractUnderTest = new MockERC20({name: "MockERC20", symbol: "MERC"});
        vm.label({account: address(contractUnderTest), newLabel: "MockERC20"});
        vm.stopPrank();
    }
}

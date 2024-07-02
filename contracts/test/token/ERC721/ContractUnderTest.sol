// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {MockERC721} from "src/mocks/MockERC721.sol";
import "forge-std-1.8.2/Test.sol";


abstract contract ContractUnderTest is Test {
    MockERC721 internal contractUnderTest;

    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));

    function setUp() public virtual {
        vm.startPrank({msgSender: deployer});
        contractUnderTest = new MockERC721({name: "MockERC721", symbol: "MERC"});
        vm.label({account: address(contractUnderTest), newLabel: "MockERC721"});
        vm.stopPrank();
    }
}

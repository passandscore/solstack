// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";

contract FreeMint_Initialize is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();

        // Make the Deployer the default caller in this test suite.
        vm.startPrank({msgSender: deployer});
    }

    function test_should_set_name() external {
        assertEq(freemintContract.name(), "FreeMint");
    }

    function test_should_set_symbol() external {
        assertEq(freemintContract.symbol(), "FM");
    }

    function test_should_set_BaseURI() external {
        assertEq(freemintContract._assetURI(), "test.com");
    }

    function test_should_set_owner() external {
        assertEq(freemintContract.owner(), address(deployer));
    }

    function test_when_already_initialized() external {
        vm.expectRevert("Initializable: contract is already initialized");

        freemintContract.initialize("FreeMint", "FM", "test.com");
    }
}

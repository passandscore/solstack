// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";

contract Initialize is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();

        // Make the Deployer the default caller in this test suite.
        vm.startPrank({msgSender: _deployer});
    }

    function testShouldSetName() external view {
        assertEq(_freemintContract.name(), "SingleFreeMint");
    }

    function testShouldSetSymbol() external view {
        assertEq(_freemintContract.symbol(), "SM");
    }

    function testShouldSetBaseURI() external view {
        assertEq(_freemintContract.assetBaseURI(), "test.com");
    }

    function testShouldSetOwner() external view {
        assertEq(_freemintContract.owner(), address(_deployer));
    }

    function testShouldRevertWhenAlreadyInitialized() external {
        vm.expectRevert("Initializable: contract is already initialized");

        _freemintContract.initialize("SingleFreeMint", "SM", "test.com");
    }
}

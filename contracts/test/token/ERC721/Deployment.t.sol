// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";

contract ERC721_Deployment is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_set_name() external view {
        assertEq(contractUnderTest.name(), "MockERC721");
    }

    function test_should_set_symbol() external view {
        assertEq(contractUnderTest.symbol(), "MERC");
    }

}

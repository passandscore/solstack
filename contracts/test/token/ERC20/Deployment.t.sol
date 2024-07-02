// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";

contract ERC20_Deployment is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_set_name() external view {
        assertEq(contractUnderTest.name(), "MockERC20");
    }

    function test_should_set_symbol() external view {
        assertEq(contractUnderTest.symbol(), "MERC");
    }

    function test_should_set_decimals() external view {
        assertEq(contractUnderTest.decimals(), 18);
    }

    function test_should_set_totalSupply() external view {
        assertEq(contractUnderTest.totalSupply(), TOTAL_SUPPLY);
    }

    function test_should_set_deployer_balance_to_totalSupply() external view {
        assertEq(contractUnderTest.balanceOf(deployer), TOTAL_SUPPLY);
    }
}

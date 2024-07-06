// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {FixedERC20} from "../src/FixedERC20.sol";

import {Test} from "@forge-std/Test.sol";
import {Fork} from "./utils/Fork.sol";

abstract contract Base is Test, Fork {
    FixedERC20 contractUnderTest;

    address payable deployer = payable(makeAddr("deployer"));

    function deploy() public {
        runFork();
        vm.selectFork(mainnetFork);

        string memory name = "FixedERC20";
        string memory symbol = "FIXED";
        uint8 decimals = 18;

        vm.startPrank(deployer);
        contractUnderTest = new FixedERC20(
            name,
            symbol,
            type(uint256).max,
            decimals
        );

        vm.label(address(contractUnderTest), "contractUnderTest");
        vm.label(deployer, "deployer");

        vm.stopPrank();
    }
}

contract Deployment is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_set_name() public view {
        assertEq("FixedERC20", contractUnderTest.name());
    }

    function test_should_set_symbol() public view {
        assertEq("FIXED", contractUnderTest.symbol());
    }

    function test_should_set_decimals() public view {
        assertEq(18, contractUnderTest.decimals());
    }

    function test_should_mint_total_supply() public view {
        assertEq(type(uint256).max, contractUnderTest.totalSupply());
        assertEq(type(uint256).max, contractUnderTest.balanceOf(deployer));
        assertEq(contractUnderTest.totalSupply(), contractUnderTest.balanceOf(deployer));
    }
}




// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import {CustomErrors} from "src/upgradeable/ShardsRWA/CustomErrors.sol";

contract ERC721Core_SetMultipler is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_called_by_non_authorized_caller() external {
        vm.startPrank(unauthorizedUser);
        
        uint16[] memory quantities = new uint16[](1);
        quantities[0] = 1;
        string[] memory multipliers = new string[](1);
        multipliers[0] = "1.5";

        bytes4 selector = OwnableUpgradeable.OwnableUnauthorizedAccount.selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        shardsRWA.batchSetMultipliers(quantities, multipliers);
    }

    function test_should_revert_when_shard_quantity_is_not_valid() external {
        uint16[] memory quantities = new uint16[](1);
        quantities[0] = 3; // Invalid quantity
        string[] memory multipliers = new string[](1);
        multipliers[0] = "1";

        vm.startPrank(deployer);
        vm.expectRevert(CustomErrors.InvalidShardQuantity.selector);
        shardsRWA.batchSetMultipliers(quantities, multipliers);
    }

    function test_should_set_multiplier() external {
        uint16[] memory quantities = new uint16[](1);
        quantities[0] = 1;
        string[] memory multipliers = new string[](1);
        multipliers[0] = "5";

        vm.startPrank(deployer);
        shardsRWA.batchSetMultipliers(quantities, multipliers);

        string memory multiplier = shardsRWA.getMultipler(quantities[0]);
        assertEq(multiplier, multipliers[0]);
    }

    function test_should_set_multiple_multipliers() external {
        uint16[] memory quantities = new uint16[](6);
        quantities[0] = 1;
        quantities[1] = 5;
        quantities[2] = 10;
        quantities[3] = 25;
        quantities[4] = 50;
        quantities[5] = 100;
        
        string[] memory multipliers = new string[](6);
        multipliers[0] = "1.1";
        multipliers[1] = "1.2";
        multipliers[2] = "1.3";
        multipliers[3] = "1.4";
        multipliers[4] = "1.5";
        multipliers[5] = "1";

        vm.startPrank(deployer);
        shardsRWA.batchSetMultipliers(quantities, multipliers);

        for (uint256 i = 0; i < quantities.length; i++) {
            string memory multiplier = shardsRWA.getMultipler(quantities[i]);
            assertEq(multiplier, multipliers[i]);
        }
    }

    function test_should_revert_when_array_lengths_mismatch() external {
        uint16[] memory quantities = new uint16[](2);
        quantities[0] = 1;
        quantities[1] = 5;
        
        string[] memory multipliers = new string[](1);
        multipliers[0] = "1.1";

        vm.startPrank(deployer);
        vm.expectRevert("Array lengths must match");
        shardsRWA.batchSetMultipliers(quantities, multipliers);
    }
}

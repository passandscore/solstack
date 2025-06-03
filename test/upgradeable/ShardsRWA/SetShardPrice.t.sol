// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {CustomErrors} from "src/upgradeable/ShardsRWA/CustomErrors.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";


contract SetShardPriceTest is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_BatchSetShardPrices() public {
        vm.startPrank(deployer);
        
        uint16[] memory quantities = new uint16[](6);
        quantities[0] = 1;
        quantities[1] = 5;
        quantities[2] = 10;
        quantities[3] = 25;
        quantities[4] = 50;
        quantities[5] = 100;
        
        uint256[] memory prices = new uint256[](6);
        prices[0] = 0.00614 ether;
        prices[1] = 0.00246 ether;
        prices[2] = 0.00246 ether;
        prices[3] = 0.00246 ether;
        prices[4] = 0.00225 ether;
        prices[5] = 0.00225 ether;
        
        shardsRWA.batchSetShardPrices(quantities, prices, false);
        
        for (uint256 i = 0; i < quantities.length; i++) {
            assertEq(shardsRWA.getShardPricePerPack(quantities[i], false), prices[i]);
        }
        
        vm.stopPrank();
    }

    function test_BatchSetWhitelistPrices() public {
        vm.startPrank(deployer);
        
        uint16[] memory quantities = new uint16[](6);
        quantities[0] = 1;
        quantities[1] = 5;
        quantities[2] = 10;
        quantities[3] = 25;
        quantities[4] = 50;
        quantities[5] = 100;
        
        uint256[] memory prices = new uint256[](6);
        prices[0] = 0.006 ether;
        prices[1] = 0.002 ether;
        prices[2] = 0.002 ether;
        prices[3] = 0.002 ether;
        prices[4] = 0.0022 ether;
        prices[5] = 0.0022 ether;
        
        shardsRWA.batchSetShardPrices(quantities, prices, true);
        
        for (uint256 i = 0; i < quantities.length; i++) {
            assertEq(shardsRWA.getShardPricePerPack(quantities[i], true), prices[i]);
        }
        
        vm.stopPrank();
    }

    function test_BatchSetPrices_InvalidQuantity() public {
        vm.startPrank(deployer);
        
        uint16[] memory quantities = new uint16[](1);
        quantities[0] = 2; // Invalid quantity
        
        uint256[] memory prices = new uint256[](1);
        prices[0] = 0.1 ether;
        
        vm.expectRevert(CustomErrors.InvalidShardQuantity.selector);
        shardsRWA.batchSetShardPrices(quantities, prices, false);
        
        vm.stopPrank();
    }

    function test_BatchSetPrices_ArrayLengthMismatch() public {
        vm.startPrank(deployer);
        
        uint16[] memory quantities = new uint16[](2);
        quantities[0] = 1;
        quantities[1] = 5;
        
        uint256[] memory prices = new uint256[](1);
        prices[0] = 0.1 ether;
        
        vm.expectRevert("Array lengths must match");
        shardsRWA.batchSetShardPrices(quantities, prices, false);
        
        vm.stopPrank();
    }

    function test_BatchSetPrices_OnlyOwner() public {
        vm.startPrank(unauthorizedUser);
        uint16[] memory quantities = new uint16[](1);
        quantities[0] = 1;
        
        uint256[] memory prices = new uint256[](1);
        prices[0] = 0.1 ether;
        
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, unauthorizedUser));
        shardsRWA.batchSetShardPrices(quantities, prices, false);
    }
}
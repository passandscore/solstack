// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {ShardRandomness} from "src/upgradable/ShardsRWA/ShardRandomness.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";

contract ERC721Core_GetTokensByOwner is ContractUnderTest {

    function setUp() public virtual override {
        ContractUnderTest.setUp();

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        uint256 price = calculateTotalPrice(5);
        shardsRWA.mintSingleShards{value: price}(deployer, 5, false);
        vm.stopPrank();
    }

    function test_should_return_count_of_tokens_owned_by_the_caller()
        public
        view
    {
        uint256[] memory tokenIds = shardsRWA.getTokensByOwner(deployer);

        assertEq(tokenIds.length, 5);
    }

    function test_should_return_proper_tokenIds_owned_by_the_caller() public {
        uint256 price;

        // mint tokens 6, 7, 8, 9, 10
        vm.startPrank(user1);
        price = calculateTotalPrice(5);
        shardsRWA.mintSingleShards{value: price}(user1, 5, false);
        vm.stopPrank();

        // mint tokens 11, 12, 13, 14, 15
        vm.startPrank(user2);
        price = calculateTotalPrice(5);
        shardsRWA.mintSingleShards{value: price}(user2, 5, false);
        vm.stopPrank();

        // mint tokens 16, 17, 18, 19, 20
        vm.startPrank(user1);
        price = calculateTotalPrice(5);
        shardsRWA.mintSingleShards{value: price}(user1, 5, false);
        vm.stopPrank();

        uint256[] memory tokenIds = shardsRWA.getTokensByOwner(user2);

        assertEq(tokenIds[0], 11);
        assertEq(tokenIds[1], 12);
        assertEq(tokenIds[2], 13);
        assertEq(tokenIds[3], 14);
        assertEq(tokenIds[4], 15);
    }
}

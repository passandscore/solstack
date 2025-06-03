// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import {CustomErrors} from "src/upgradeable/ShardsRWA/CustomErrors.sol";

contract ERC721Core_AdminMintSingleShard is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_mint_when_open() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.adminMintSingleShard(1, user1);

        assertEq(shardsRWA.totalSupply(), 1);
    }

    function test_should_revert_when_caller_is_not_owner() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        vm.stopPrank();

        vm.startPrank(unauthorizedUser);
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        shardsRWA.adminMintSingleShard(1, user1);
    }

    function test_should_mint_when_paused() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        shardsRWA.toggleMintingPaused();

        shardsRWA.adminMintSingleShard(1, user1);

        assertEq(shardsRWA.totalSupply(), 1);
    }

    function test_should_mint_when_not_started() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp + 1 days, block.timestamp + 2 days);

        shardsRWA.adminMintSingleShard(1, user1);

        assertEq(shardsRWA.totalSupply(), 1);
    }

    function test_should_mint_when_closed() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        vm.warp(block.timestamp + 3 days);

        shardsRWA.adminMintSingleShard(1, user1);

        assertEq(shardsRWA.totalSupply(), 1);
    }

    function test_should_mint_more_than_one_token() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.adminMintSingleShard(1, user1);
        shardsRWA.adminMintSingleShard(5, user2);

        assertEq(shardsRWA.totalSupply(), 6);
    }

    function test_should_transfer_token_owner_after_mint() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.adminMintSingleShard(1, user1);

        assertEq(shardsRWA.ownerOf(1), user1);
    }

    function test_should_mint_50_shards_to_user() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.adminMintSingleShard(50, user1);

        assertEq(shardsRWA.totalSupply(), 50);

        for (uint256 i = 0; i < 50; i++) {
            assertEq(shardsRWA.ownerOf(i + 1), user1);
        }
    }

    function test_should_revert_when_passing_invalid_shard_quantity() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        vm.expectRevert(CustomErrors.InvalidShardQuantity.selector);

        shardsRWA.adminMintSingleShard(0, user1);
    }

    function test_should_revert_when_exceeding_MAX_TOKEN_SUPPLY() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        shardsRWA.setMaxSupply(10);

        vm.expectRevert(CustomErrors.TotalSupplyExceeded.selector);

        shardsRWA.adminMintSingleShard(25, user1);
    }
}

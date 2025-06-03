// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {ShardRandomness} from "src/upgradeable/ShardsRWA/ShardRandomness.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";

contract ERC721Core_GetShardDataByTokenId is ContractUnderTest {

    function setUp() public virtual override {
        ContractUnderTest.setUp();

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        uint256 price = calculateTotalPrice(5);
        shardsRWA.mintSingleShards{value: price}(deployer, 5, false);
        vm.stopPrank();
    }

    function test_should_return_metadata_for_shard() public view {
        uint256 tokenId = 1;

        ShardRandomness.ShardMetadata memory shardMetadata = shardsRWA
            .getShardDataByTokenId(tokenId);

        uint16 x = shardMetadata.x;
        uint16 y = shardMetadata.y;
        string memory multiplier = shardMetadata.multiplier;

        assertTrue(x >= 0 && x < shardsRWA.GRID_SIDE());
        assertTrue(y >= 0 && y < shardsRWA.GRID_SIDE());
        assertTrue(bytes(multiplier).length > 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {ShardRandomness} from "src/upgradeable/ShardsRWA/ShardRandomness.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721Core_ImageURITest is ContractUnderTest {
    function testShardCoordinatesInTokenURI() public {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        uint256 price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        uint256 tokenId = 1;

        ShardRandomness.ShardMetadata memory shardMetadata = shardsRWA
            .getShardDataByTokenId(tokenId);

        // Retrieve the image URL
        string memory imageURI = shardsRWA.imageURI(tokenId);

        // Verify that the image URL contains the correct shard_x_coordinate and shard_y_coordinate
        string memory expectedImageURI = string(
            abi.encodePacked(
                shardsRWA.baseURI(),
                Strings.toString(shardMetadata.x),
                "_",
                Strings.toString(shardMetadata.y),
                ".png"
            )
        );

        assertEq(
            imageURI,
            expectedImageURI,
            "Image URI does not match expected format."
        );
    }
}

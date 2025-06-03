// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {ShardRandomness} from "../ShardRandomness.sol";

library MetadataLib {
    /**
     * @dev Returns the URI for a given token ID asset.
     * @param baseURI The base URI for the asset.
     * @param x The x coordinate of the shard.
     * @param y The y coordinate of the shard.
     */
    function imageURI(string memory baseURI, uint256 x, uint256 y)
        internal
        pure
        returns (string memory uri)
    {
        uri = string(abi.encodePacked(baseURI, Strings.toString(x), "_", Strings.toString(y), ".png"));
    }

    /**
     * @dev Returns the token metadata for a given token ID asset.
     * @param tokenId The token ID to retrieve the metadata for.
     * @param baseURI The base URI for the asset.
     * @param x The x coordinate of the shard.
     * @param y The y coordinate of the shard.
     */
    function tokenURI(
        uint256 tokenId,
        string memory baseURI,
        string memory nftName,
        string memory artistName,
        string memory description,
        string memory multiplier,
        uint256 x,
        uint256 y
    ) internal pure returns (string memory) {
        string memory imageUri =
            string(abi.encodePacked(baseURI, Strings.toString(x), "_", Strings.toString(y), ".png"));

        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "',
                        nftName,
                        " #",
                        Strings.toString(tokenId),
                        '", "tokenId": "',
                        Strings.toString(tokenId),
                        '", "image": "',
                        imageUri,
                        '", "properties": { "artistName": "',
                        artistName,
                        '", "shard_x_coordinate": "',
                        Strings.toString(x),
                        '", "shard_y_coordinate": "',
                        Strings.toString(y),
                        '", "multiplier": "',
                        multiplier,
                        '"}, "description": "',
                        description,
                        '"}'
                    )
                )
            )
        );
        return metadata;
    }
}

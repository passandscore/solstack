// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721EnumerableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

abstract contract ShardRandomness {
    // Constants
    uint256 public constant FULL_GRID_QUANTITY = 100;

    struct ShardMetadata {
        uint16 x;
        uint16 y;
        string multiplier;
    }

    function totalSupply() public view virtual returns (uint256) {
        return ERC721EnumerableUpgradeable(address(this)).totalSupply();
    }

    function getPackMetadata() internal view returns (ShardMetadata[] memory) {
        ShardMetadata[] memory shards = new ShardMetadata[](FULL_GRID_QUANTITY);
        uint256 currentSupply = totalSupply();

        for (uint256 i = 0; i < FULL_GRID_QUANTITY; i++) {
            shards[i] = ShardMetadata({
                x: uint16((currentSupply + i + 1) % 10),
                y: uint16((currentSupply + i + 1) / 10),
                multiplier: ""
            });
        }

        return shards;
    }

    function getShardMetadata() internal view returns (ShardMetadata memory) {
        uint256 currentSupply = totalSupply();
        return ShardMetadata({
            x: uint16((currentSupply + 1) % 10),
            y: uint16((currentSupply + 1) / 10),
            multiplier: ""
        });
    }
} 
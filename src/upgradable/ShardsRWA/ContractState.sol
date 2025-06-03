// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ShardRandomness} from "./ShardRandomness.sol";

abstract contract StorageSlots {
    /// @dev A struct representing the Core Storage of the contract.
    /// @custom:storage-location erc7201:ShardsRWA.storage.CoreStorage
    struct CoreStorage {
        // shardQuantity(1,5,10,25,50,100) => multiplier (1.1, 1.2, 1.3, 1.4, 1.5, 1)
        mapping(uint16 => string) shardMultiplier;
        mapping(uint16 => uint256) shardPricePerPack;
        mapping(uint16 => uint256) wlShardPricePerPack;
        uint256 maxSupply;
        string nftName;
        string artistName;
        string description;
        string baseURI;
        uint32 mintStartTime;
        uint32 mintEndTime;
        bool mintingPaused;
        bool tradingRestricted;
    }

    /// @custom:storage-location erc7201:ShardsRWA.storage.ShardStorage
    struct ShardStorage {
        mapping(uint256 => ShardRandomness.ShardMetadata) shardMetadata;
    }

    /// @custom:storage-location erc7201:ShardsRWA.storage.RoyaltyReceiver
    struct RoyaltyReceiver {
        address payable wallet;
        uint48 primarySalePercentage;
        uint48 secondarySalePercentage;
    }

    /// @custom:storage-location erc7201:ShardsRWA.storage.Whitelist
    struct Whitelist {
        bytes32 merkleRoot;
        uint256 totalHoursOpen;
        bool whitelistEnabled;
    }
}

library State {
    function _getCoreStorage() internal pure returns (StorageSlots.CoreStorage storage state) {
        bytes32 storageSlot = keccak256("liveart.fractionalization.core");
        assembly {
            state.slot := storageSlot
        }
    }

    function _getShardStorage() internal pure returns (StorageSlots.ShardStorage storage state) {
        bytes32 storageSlot = keccak256("liveart.fractionalization.shard");
        assembly {
            state.slot := storageSlot
        }
    }

    function _getRoyaltyStorage() internal pure returns (StorageSlots.RoyaltyReceiver storage state) {
        bytes32 storageSlot = keccak256("liveart.RoyalitiesState");
        assembly {
            state.slot := storageSlot
        }
    }

    function _getWhitelistStorage() internal pure returns (StorageSlots.Whitelist storage state) {
        bytes32 storageSlot = keccak256("liveart.whitelistState");
        assembly {
            state.slot := storageSlot
        }
    }
}

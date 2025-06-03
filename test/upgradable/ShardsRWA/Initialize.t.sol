// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {Initializable} from "@openzeppelin-contracts-upgradeable-5.0.2/proxy/utils/Initializable.sol";

contract ERC721Core_Initialize is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();

        // Make the Deployer the default caller in this test suite.
        vm.startPrank({msgSender: deployer});
    }

    function test_should_set_name() external view {
        assertEq(shardsRWA.name(), "ShardsRWA");
    }

    function test_should_set_symbol() external view {
        assertEq(shardsRWA.symbol(), "ERC721");
    }

    function test_should_set_owner() external view {
        assertEq(shardsRWA.owner(), address(deployer));
    }

    function test_should_set_baseURI() external view {
        assertEq(shardsRWA.baseURI(), "https://api.example.com/v1/");
    }

    function test_should_set_shard_prices() external view{
        // loop 1, 3, 5, 10, 25, 50 , 100
        uint8[6] memory shardPacks = [1, 5, 10, 25, 50, 100];

        for(uint8 i = 0; i < shardPacks.length; i++) {
            uint256 shardPrice = shardsRWA.getShardPricePerPack(shardPacks[i], false);
            assertGe(shardPrice, 0);
        }
    }

    function test_should_set_maxSupply() external view {
        assertEq(shardsRWA.maxSupply(), 50000);
    }

    function test_should_set_royaltyReceiver() external view {
        assertEq(shardsRWA.royaltyReceiver(), royaltyReceiver);
    }

    function test_should_set_tokenContractAddress() external view {
        assertEq(address(shardsRWA.tokenContractAddress()), address(mockERC20Token));
    }

    function test_when_already_initialized() external {
        // string memory name = "ShardsRWA";
        // string memory symbol = "ERC721";
        // string memory baseURI = "https://api.example.com/v1/";
        // uint256 maxSupply = 50000;


        vm.expectRevert(Initializable.InvalidInitialization.selector);

        shardsRWA.initialize(
            "ShardsRWA",
            "ERC721",
            "https://api.example.com/v1/",
            50000,
            10000,
            500,
            royaltyReceiver,
            address(mockERC20Token)
        );
    }
}

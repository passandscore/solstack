// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import {CustomErrors} from "src/upgradeable/ShardsRWA/CustomErrors.sol";

contract ERC721Core_BatchAdminMintSingleShard is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
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

        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        uint16[] memory tokenIds = new uint16[](1);
        tokenIds[0] = 1;

        shardsRWA.batchMintSingleShards(tokenIds, recipients);
    }

    function test_should_revert_when_InvalidBatchLength() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        uint16[] memory tokenIds = new uint16[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        vm.expectRevert(CustomErrors.InvalidBatchLength.selector);

        shardsRWA.batchMintSingleShards(tokenIds, recipients);
    }

    function test_should_revert_when_recipients_array_is_empty() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        address[] memory recipients = new address[](0);

        uint16[] memory tokenIds = new uint16[](1);
        tokenIds[0] = 1;

        vm.expectRevert(CustomErrors.InvalidBatchLength.selector);

        shardsRWA.batchMintSingleShards(tokenIds, recipients);
    }

    function test_should_revert_when_tokenIds_array_is_empty() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        uint16[] memory tokenIds = new uint16[](0);

        vm.expectRevert(CustomErrors.InvalidBatchLength.selector);

        shardsRWA.batchMintSingleShards(tokenIds, recipients);
    }

    function test_should_successfully_mint_when_open() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        address[] memory recipients = new address[](10);
        for (uint i = 0; i < 5; i++) {
            recipients[i] = user1;
        }

        for (uint i = 5; i < 10; i++) {
            recipients[i] = user2;
        }

        uint16[] memory quantities = new uint16[](10);
        for (uint i = 0; i < 10; i++) {
            quantities[i] = uint16(1);
        }

        shardsRWA.batchMintSingleShards(quantities, recipients);

        assertEq(shardsRWA.totalSupply(), 10);

        // check ownerOf
        for (uint i = 1; i < 6; i++) {
            assertEq(shardsRWA.ownerOf(uint16(i)), user1);
        }

        for (uint i = 6; i < 11; i++) {
            assertEq(shardsRWA.ownerOf(uint16(i)), user2);
        }
    }
}

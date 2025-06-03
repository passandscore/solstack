// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import {CustomErrors} from "src/upgradable/ShardsRWA/CustomErrors.sol";

contract ERC721Core_AdminMintMaxPack is ContractUnderTest {
    uint16 defaultNumberOfPacksToMint = 1;

    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_mint_when_open() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.adminMintMaxPack(user1, defaultNumberOfPacksToMint);

        assertEq(shardsRWA.totalSupply(), 100);
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

        shardsRWA.adminMintMaxPack(user1, defaultNumberOfPacksToMint);
    }

    function test_should_mint_when_paused() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        shardsRWA.toggleMintingPaused();

        shardsRWA.adminMintMaxPack(user1, defaultNumberOfPacksToMint);

        assertEq(shardsRWA.totalSupply(), 100);
    }

    function test_should_mint_when_not_started() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp + 1 days, block.timestamp + 2 days);

        shardsRWA.adminMintMaxPack(user1, defaultNumberOfPacksToMint);

        assertEq(shardsRWA.totalSupply(), 100);
    }

    function test_should_mint_when_closed() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        vm.warp(block.timestamp + 3 days);

        shardsRWA.adminMintMaxPack(user1, defaultNumberOfPacksToMint);

        assertEq(shardsRWA.totalSupply(), 100);
    }

    function test_should_transfer_token_owner_after_mint() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.adminMintMaxPack(user1, defaultNumberOfPacksToMint);

        assertEq(shardsRWA.ownerOf(1), user1);
    }

    function test_should_revert_when_exceeding_MAX_TOKEN_SUPPLY() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        shardsRWA.setMaxSupply(10);

        vm.expectRevert(CustomErrors.TotalSupplyExceeded.selector);

        shardsRWA.adminMintMaxPack(user1, defaultNumberOfPacksToMint);
    }
}

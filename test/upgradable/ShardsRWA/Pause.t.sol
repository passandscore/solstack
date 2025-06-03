// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {CustomErrors} from "src/upgradable/ShardsRWA/CustomErrors.sol";

contract ERC721Core_Pause is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_setting_mint_paused_as_unauthorized_user()
        external
    {
        vm.startPrank(unauthorizedUser);
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));
        shardsRWA.toggleMintingPaused();
    }

    function test_should_revert_when_resuming_mint_as_unauthorized_user()
        external
    {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;
        vm.startPrank(deployer);
        setMintingWindow(startTime, endTime);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 totalPrice = shardsRWA.getShardPricePerPack(1, false);
        shardsRWA.mintSingleShards{value: totalPrice}(user1, 1, false);
        vm.stopPrank();

        vm.startPrank(deployer);
        shardsRWA.toggleMintingPaused();
        vm.stopPrank();

        vm.startPrank(unauthorizedUser);
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));
        vm.stopPrank();

        vm.startPrank(unauthorizedUser);
        shardsRWA.toggleMintingPaused();
    }

    function test_should_pause_mint() external {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;

        vm.startPrank(deployer);
        setMintingWindow(startTime, endTime);
        vm.stopPrank();

        uint256 totalPrice = shardsRWA.getShardPricePerPack(1, false);
        shardsRWA.mintSingleShards{value: totalPrice}(deployer, 1, false);

        vm.startPrank(user1);
        shardsRWA.mintSingleShards{value: totalPrice}(user1, 1, false);
        vm.stopPrank();

        vm.startPrank(user2);
        shardsRWA.mintSingleShards{value: totalPrice}(user2, 1, false);
        vm.stopPrank();

        vm.warp(endTime + 1);

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);
        shardsRWA.mintSingleShards{value: totalPrice}(deployer, 1, false);
    }

    function test_should_resume_mint() external {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;

        vm.startPrank(deployer);
        setMintingWindow(startTime, endTime);
        vm.stopPrank();

        uint256 totalPrice = shardsRWA.getShardPricePerPack(1, false);
        shardsRWA.mintSingleShards{value: totalPrice}(deployer, 1, false);

        vm.startPrank(deployer);
        shardsRWA.toggleMintingPaused();
        vm.stopPrank();

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);

        vm.startPrank(user1);
        shardsRWA.mintSingleShards{value: totalPrice}(user1, 1, false);
        vm.stopPrank();

        vm.startPrank(deployer);
        shardsRWA.toggleMintingPaused();
        vm.stopPrank();

        vm.startPrank(user2);
        shardsRWA.mintSingleShards{value: totalPrice}(user2, 1, false);
        vm.stopPrank();

        assertEq(shardsRWA.totalSupply(), 2);
    }
}

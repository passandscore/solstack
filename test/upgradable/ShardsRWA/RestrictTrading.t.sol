// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {Initializable} from "@openzeppelin-contracts-upgradeable-5.0.2/proxy/utils/Initializable.sol";
import {CustomErrors} from "src/upgradable/ShardsRWA/CustomErrors.sol";

contract ERC721Core_RestrictTrading is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_restrict_transfers_when_enabled() external {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        // transfer token to user1
        vm.expectRevert(CustomErrors.TradingRestricted.selector);
        shardsRWA.transferFrom(deployer, user1, 1);
    }

    function test_should_prevent_approving_single_transfers_when_enabled()
        external
    {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        // approve token to user1
        vm.expectRevert(CustomErrors.TradingRestricted.selector);
        shardsRWA.approve(user1, 1);
    }

    function test_should_prevent_approving_all_transfers_when_enabled()
        external
    {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        // approve all token to user1
        vm.expectRevert(CustomErrors.TradingRestricted.selector);
        shardsRWA.setApprovalForAll(user1, true);
    }

    function test_should_prevent_safe_transfers_when_enabled() external {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        // safe transfer token to user1
        vm.expectRevert(CustomErrors.TradingRestricted.selector);
        shardsRWA.safeTransferFrom(deployer, user1, 1);
    }

    function test_should_allow_transfers_when_disabled() external {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        // disable trading
        vm.startPrank(deployer);
        shardsRWA.toggleTradingRestricted();

        // transfer token to user1
        shardsRWA.transferFrom(deployer, user1, 1);
    }

    function test_should_allow_approving_single_transfers_when_disabled() external {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        // disable trading
        vm.startPrank(deployer);
        shardsRWA.toggleTradingRestricted();

        // approve token to user1
        shardsRWA.approve(user1, 1);
    }

    function test_should_allow_approving_all_transfers_when_disabled() external {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        // disable trading
        vm.startPrank(deployer);
        shardsRWA.toggleTradingRestricted();

        // approve all token to user1
        shardsRWA.setApprovalForAll(user1, true);
    }

    function test_should_allow_safe_transfers_when_disabled() external {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        // disable trading
        vm.startPrank(deployer);
        shardsRWA.toggleTradingRestricted();

        // safe transfer token to user1
        shardsRWA.safeTransferFrom(deployer, user1, 1);
    }

    function test_should_revert_when_trading_is_restricted() external {
        uint256 price;
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        // transfer token to user1
        vm.expectRevert(CustomErrors.TradingRestricted.selector);
        shardsRWA.transferFrom(deployer, user1, 1);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {CustomErrors} from "src/upgradable/ShardsRWA/CustomErrors.sol";

contract ERC721_MintSingleShards is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
        setDefaultPricesAndMultipliers();
    }

    function test_should_revert_when_price_not_set() external {
        vm.startPrank(deployer);
        uint16[] memory quantities = new uint16[](1);
        quantities[0] = 1;
        uint256[] memory prices = new uint256[](1);
        prices[0] = 0;
        shardsRWA.batchSetShardPrices(quantities, prices, false);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        vm.stopPrank();

        vm.expectRevert(CustomErrors.PriceNotSet.selector);
        shardsRWA.mintSingleShards{value: 0.5 ether}(deployer, 1, false);
    }

    function test_should_revert_when_mint_paused_and_no_duration_set()
        external
    {
        uint256 price = calculateTotalPrice(1);

        vm.startPrank(deployer);
        shardsRWA.toggleMintingPaused();
        vm.stopPrank();

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);
    }

    function test_should_revert_when_duration_set_but_minting_paused()
        external
    {
        uint256 price = calculateTotalPrice(1);

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.toggleMintingPaused();

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);
        vm.stopPrank();
    }

    function test_should_revert_when_minting_with_insufficient_funds()
        external
    {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 price = calculateTotalPrice(1);
        vm.expectRevert(CustomErrors.InsufficientFunds.selector);
        shardsRWA.mintSingleShards{value: price - 1}(user1, 1, false);
    }

    function test_should_revert_when_minting_duration_has_ended() external {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;
        uint256 price = calculateTotalPrice(1);

        vm.startPrank(deployer);
        setMintingWindow(startTime, endTime);

        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);
        vm.stopPrank();

        vm.startPrank(user1);
        shardsRWA.mintSingleShards{value: price}(user1, 1, false);
        vm.stopPrank();

        vm.startPrank(user2);
        shardsRWA.mintSingleShards{value: price}(user2, 1, false);
        vm.stopPrank();

        vm.warp(endTime + 1);

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);
    }

    function test_should_revert_when_exceeding_MAX_TOKEN_SUPPLY() external {
        vm.startPrank(deployer);
        uint256 price = calculateTotalPrice(10);

        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        shardsRWA.setMaxSupply(5);

        vm.expectRevert(CustomErrors.TotalSupplyExceeded.selector);

        shardsRWA.mintSingleShards{value: price}(deployer, 10, false);
    }

    function test_should_revert_when_passing_invalid_shard_quantity() external {
        uint256 price = calculateTotalPrice(3);

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        vm.expectRevert(CustomErrors.InvalidShardQuantity.selector);

        shardsRWA.mintSingleShards{value: price}(deployer, 3, false);
    }

    function test_should_revert_when_user_over_pays() external {
        uint256 price = calculateTotalPrice(1);

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        vm.expectRevert(CustomErrors.InsufficientFunds.selector);

        shardsRWA.mintSingleShards{value: price + 1}(deployer, 1, false);
    }

    function test_should_mint_when_unpaused_and_then_revert_when_paused()
        external
    {
        vm.startPrank(deployer);
        uint256 price = calculateTotalPrice(1);

        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        shardsRWA.toggleMintingPaused();
        vm.stopPrank();

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);

        vm.startPrank(user1);
        shardsRWA.mintSingleShards{value: price}(user1, 1, false);
    }

    function test_should_return_zero_minted_when_none_minted() external view {
        assertEq(shardsRWA.totalSupply(), 0);
    }

    function test_should_return_proper_minted_count_when_mint_unpaused()
        external
    {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);
        vm.stopPrank();

        vm.startPrank({msgSender: user1});
        price = calculateTotalPrice(5);
        shardsRWA.mintSingleShards{value: price}(user1, 5, false);
        vm.stopPrank();

        vm.startPrank({msgSender: user2});
        price = calculateTotalPrice(10);
        shardsRWA.mintSingleShards{value: price}(user2, 10, false);

        price = calculateTotalPrice(25);
        shardsRWA.mintSingleShards{value: price}(user2, 25, false);

        price = calculateTotalPrice(50);
        shardsRWA.mintSingleShards{value: price}(user2, 50, false);
        vm.stopPrank();

        assertEq(shardsRWA.totalSupply(), 91);
    }

    function test_should_mint_when_updated_multiplier_is_set() external {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        uint16[] memory quantities = new uint16[](2);
        quantities[0] = 1;
        quantities[1] = 5;
        string[] memory multipliers = new string[](2);
        multipliers[0] = "1.5";
        multipliers[1] = "1.6";
        shardsRWA.batchSetMultipliers(quantities, multipliers);
        price = calculateTotalPrice(1);
        shardsRWA.mintSingleShards{value: price}(deployer, 1, false);

        price = calculateTotalPrice(5);
        shardsRWA.mintSingleShards{value: price}(deployer, 5, false);

        assertEq(shardsRWA.totalSupply(), 6);
    }

    function test_royalty_receiver_should_receive_royalty() external {
        uint256 price;

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        assertEq(royaltyReceiver.balance, 0);

        price = calculateTotalPrice(10);
        shardsRWA.mintSingleShards{value: price}(deployer, 10, false);

        assertEq(royaltyReceiver.balance, price);
    }

    function test_should_properly_mint_different_pack_sizes_with_token() external {
        uint16[] memory packSizes = new uint16[](5);
        packSizes[0] = 1;
        packSizes[1] = 5;
        packSizes[2] = 10;
        packSizes[3] = 25;
        packSizes[4] = 50;

        vm.startPrank(deployer);
        mockERC20Token.mint(deployer, 1000 ether);
        mockERC20Token.approve(address(shardsRWA), 1000 ether);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        uint256 totalMinted = 0;
        uint256 totalPaid = 0;

        for (uint256 i = 0; i < packSizes.length; i++) {
            uint16 packSize = packSizes[i];
            uint256 pricePerShard = shardsRWA.getShardPricePerPack(packSize, false);
            uint256 totalPrice = pricePerShard * packSize;
            uint256 initialBalance = mockERC20Token.balanceOf(deployer);
            uint256 initialSupply = shardsRWA.totalSupply();

            shardsRWA.mintSingleShards(deployer, packSize, true);

            totalMinted += packSize;
            totalPaid += totalPrice;

            assertEq(shardsRWA.totalSupply(), initialSupply + packSize);
            assertEq(mockERC20Token.balanceOf(deployer), initialBalance - totalPrice);
            assertEq(mockERC20Token.balanceOf(royaltyReceiver), totalPaid);
        }

        assertEq(shardsRWA.totalSupply(), totalMinted);
        assertEq(mockERC20Token.balanceOf(deployer), 1000 ether - totalPaid);
        assertEq(mockERC20Token.balanceOf(royaltyReceiver), totalPaid);
    }
}

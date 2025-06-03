// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {CustomErrors} from "src/upgradable/ShardsRWA/CustomErrors.sol";
import {console} from "forge-std/console.sol";

contract ERC721_MintMaxPack is ContractUnderTest {
    uint256 totalPrice;
    uint16 defaultNumberOfPacksToMint = 1;

    function setUp() public virtual override {
        ContractUnderTest.setUp();
        uint256 shardsPerPack = 100;
        setDefaultPricesAndMultipliers();
        totalPrice = shardsRWA.getShardPricePerPack(100, false) * shardsPerPack;
    }

    function test_should_revert_when_price_not_set() external {
        vm.startPrank(deployer);
        uint16[] memory quantities = new uint16[](1);
        quantities[0] = 100;
        uint256[] memory prices = new uint256[](1);
        prices[0] = 0;
        shardsRWA.batchSetShardPrices(quantities, prices, false);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        vm.stopPrank();

        vm.expectRevert(CustomErrors.PriceNotSet.selector);
        shardsRWA.mintMaxPack{value: totalPrice}(deployer, defaultNumberOfPacksToMint, false);
    }

    function test_should_revert_when_mint_paused_and_no_duration_set()
        external
    {
        vm.startPrank(deployer);
        shardsRWA.toggleMintingPaused();
        vm.stopPrank();

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);
        shardsRWA.mintMaxPack{value: totalPrice}(deployer, defaultNumberOfPacksToMint, false);
    }

    function test_should_revert_when_duration_set_but_minting_paused()
        external
    {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.toggleMintingPaused();

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);
        shardsRWA.mintMaxPack{value: totalPrice}(deployer, defaultNumberOfPacksToMint, false);
        vm.stopPrank();
    }

    function test_should_revert_when_minting_with_insufficient_funds()
        external
    {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(CustomErrors.InsufficientFunds.selector);
        shardsRWA.mintMaxPack{value: totalPrice - 1}(deployer, defaultNumberOfPacksToMint, false);
    }

    function test_should_revert_when_minting_duration_has_ended() external {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;

        vm.startPrank(deployer);
        setMintingWindow(startTime, endTime);

        shardsRWA.mintMaxPack{value: totalPrice}(deployer, defaultNumberOfPacksToMint, false);
        vm.stopPrank();

        vm.startPrank(user1);
        shardsRWA.mintMaxPack{value: totalPrice}(user1, defaultNumberOfPacksToMint, false);
        vm.stopPrank();

        vm.startPrank(user2);
        shardsRWA.mintMaxPack{value: totalPrice}(user2, defaultNumberOfPacksToMint, false);
        vm.stopPrank();

        vm.warp(endTime + 1);

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);
        shardsRWA.mintMaxPack{value: totalPrice}(deployer, defaultNumberOfPacksToMint, false);
    }

    function test_should_revert_when_exceeding_MAX_TOKEN_SUPPLY() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        shardsRWA.setMaxSupply(10);

        vm.expectRevert(CustomErrors.TotalSupplyExceeded.selector);

        shardsRWA.mintMaxPack{value: totalPrice}(deployer, defaultNumberOfPacksToMint, false);
    }

    function test_should_revert_when_user_over_pays() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(CustomErrors.InsufficientFunds.selector);
        shardsRWA.mintMaxPack{value: totalPrice + 1}(deployer, defaultNumberOfPacksToMint, false);
    }

    function test_should_mint_when_unpaused_and_then_revert_when_paused()
        external
    {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.mintMaxPack{value: totalPrice}(deployer, defaultNumberOfPacksToMint, false);

        shardsRWA.toggleMintingPaused();
        vm.stopPrank();

        vm.expectRevert(CustomErrors.MintingNotEnabled.selector);

        vm.startPrank(user1);
        shardsRWA.mintMaxPack{value: totalPrice}(user1, defaultNumberOfPacksToMint, false);
    }

    function test_should_return_zero_minted_when_none_minted() external view {
        assertEq(shardsRWA.totalSupply(), 0);
    }

    function test_should_return_proper_minted_count_when_mint_unpaused()
        external
    {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.mintMaxPack{value: totalPrice}(deployer, defaultNumberOfPacksToMint, false);
        vm.stopPrank();

        vm.startPrank({msgSender: user1});
        shardsRWA.mintMaxPack{value: totalPrice}(user1, defaultNumberOfPacksToMint, false);
        vm.stopPrank();

        vm.startPrank({msgSender: user2});
        shardsRWA.mintMaxPack{value: totalPrice}(user2, defaultNumberOfPacksToMint, false);
        vm.stopPrank();

        assertEq(shardsRWA.totalSupply(), 300);
    }

    function test_royalty_receiver_should_receive_royalty() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        assertEq(royaltyReceiver.balance, 0);

        shardsRWA.mintMaxPack{value: totalPrice}(deployer, defaultNumberOfPacksToMint, false);

        assertEq(royaltyReceiver.balance, totalPrice);
    }

    function test_should_properly_mint_multiple_packs() external {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.mintMaxPack{value: totalPrice * 2}(deployer, 2, false);

        assertEq(shardsRWA.totalSupply(), 200);
    }

    function test_should_properly_mint_multiple_packs_with_token() external {
        vm.startPrank(deployer);

        mockERC20Token.mint(deployer, 1000 ether);
        mockERC20Token.approve(address(shardsRWA), 1000 ether);

        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        shardsRWA.mintMaxPack(deployer, 2, true);

        assertEq(shardsRWA.totalSupply(), 200);
        assertEq(mockERC20Token.balanceOf(deployer), 1000 ether - totalPrice);
        assertEq(mockERC20Token.balanceOf(royaltyReceiver), totalPrice);
    }

    function test_should_revert_when_token_contract_address_is_not_set() external {
        vm.startPrank(deployer);
        shardsRWA.setTokenContractAddress(address(0));

        mockERC20Token.mint(deployer, 1000 ether);
        mockERC20Token.approve(address(shardsRWA), 1000 ether);

        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        vm.expectRevert(CustomErrors.TokenContractAddressNotSet.selector);
        shardsRWA.mintMaxPack(deployer, 2, true);
    }
}

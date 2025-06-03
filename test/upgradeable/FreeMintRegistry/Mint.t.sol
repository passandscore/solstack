// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {FreeMintRegistry} from "contracts/upgradeable/FreeMintRegistry.sol";

contract FreeMintRegistry_Mint is ContractUnderTest {
    function setUp() public override {
        super.setUp();
        
        // Register a freemint for testing
        vm.startPrank(deployer);
        singletonFreeMint.registerFreemint(
            "Test NFT",
            "ipfs://test",
            "Test Artist",
            "Test Description",
            "Test Partner",
            100,
            uint32(block.timestamp),
            uint32(block.timestamp + 2 days)
        );
        vm.stopPrank();
    }

    function test_should_mint_token_and_increment_token_count() public {
        vm.startPrank(user1);
        vm.warp(block.timestamp + 1 days);
        singletonFreeMint.mint(user1, 1, 1, "");
        
        assertEq(singletonFreeMint.totalTokensMinted(), 1);
    }

       function test_should_mint_token_and_increase_user_balance() public {
        vm.startPrank(user1);
        vm.warp(block.timestamp + 1 days);
        singletonFreeMint.mint(user1, 1, 1, "");
        
        assertEq(singletonFreeMint.balanceOf(user1, 1), 1);
    }

    function test_should_mint_token_and_increase_total_minted_supply() public {
        vm.startPrank(user1);
        vm.warp(block.timestamp + 1 days);
        singletonFreeMint.mint(user1, 1, 1, "");

        FreeMintRegistry.Freemint memory freemint = singletonFreeMint.getFreemintDetails(1);
        
        assertEq(freemint.mintedSupply, 1);
    }

    function test_should_return_uri() public {
        vm.startPrank(user1);
        vm.warp(block.timestamp + 1 days);
        singletonFreeMint.mint(user1, 1, 1, "");
        
        assertEq(singletonFreeMint.uri(1), "data:application/json;base64,eyAibmFtZSI6ICJUZXN0IE5GVCIsICJpZCI6ICIxIiwgImltYWdlIjogImlwZnM6Ly90ZXN0IiwgInByb3BlcnRpZXMiOiB7ICJhcnRpc3ROYW1lIjogIlRlc3QgQXJ0aXN0In0sICJkZXNjcmlwdGlvbiI6ICJUZXN0IERlc2NyaXB0aW9uIiwgInBhcnRuZXJOYW1lIjogIlRlc3QgUGFydG5lciIsICJwb2ludHNQZXJNaW50IjogIjEwMCJ9");
    }

    function test_should_revert_when_already_minted() public {
        vm.startPrank(user1);
        singletonFreeMint.mint(user1, 1, 1, "");
        
        vm.expectRevert(FreeMintRegistry.TokenAlreadyMinted.selector);
        singletonFreeMint.mint(user1, 1, 1, "");
    }

    function test_should_revert_when_minting_paused() public {
        vm.startPrank(deployer);
        singletonFreeMint.pauseMint(1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(FreeMintRegistry.MintingNotEnabled.selector);
        singletonFreeMint.mint(user1, 1, 1, "");
    }

    function test_should_revert_when_mint_not_started() public {
        vm.startPrank(deployer);
        singletonFreeMint.registerFreemint(
            "Test NFT 2",
            "ipfs://test",
            "Test Artist",
            "Test Description",
            "Test Partner",
            100,
            uint32(block.timestamp + 2 days), // Starts in the future
            uint32(block.timestamp + 3 days)
        );
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(FreeMintRegistry.MintingNotEnabled.selector);
        singletonFreeMint.mint(user1, 2, 1, "");
    }

    function test_should_revert_when_mint_ended() public {
        vm.warp(block.timestamp + 3 days); // Move time past end

        vm.startPrank(user1);
        vm.expectRevert(FreeMintRegistry.MintingNotEnabled.selector);
        singletonFreeMint.mint(user1, 2, 1, "");
    }

    function test_should_revert_when_invalid_quantity() public {
        vm.startPrank(user1);
        vm.expectRevert(FreeMintRegistry.InvalidInput.selector);
        singletonFreeMint.mint(user1, 1, 0, "");

        vm.expectRevert(FreeMintRegistry.InvalidInput.selector);
        singletonFreeMint.mint(user1, 1, 2, "");
    }

    function test_should_mint_with_price() public {
        vm.startPrank(deployer);
        singletonFreeMint.updateMintPrice(1, 1 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        singletonFreeMint.mint{value: 1 ether}(user1, 1, 1, "");
    }

    function test_should_revert_when_insufficient_funds() public {
        vm.startPrank(deployer);
        singletonFreeMint.updateMintPrice(1, 1 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(FreeMintRegistry.InsufficientFunds.selector);
        singletonFreeMint.mint(user1, 1, 1, "");
    }
} 

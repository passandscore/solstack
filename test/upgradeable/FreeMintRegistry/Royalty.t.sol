// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {FreeMintRegistry} from "contracts/upgradeable/FreeMintRegistry.sol";

contract FreeMintRegistry_Royalty is ContractUnderTest {
    event RoyaltyInfoUpdated(uint256 indexed tokenId, address receiver, uint96 royaltyFraction);

    // Test constants
    uint96 constant ROYALTY_FRACTION = 500; // 5%
    uint256 constant SALE_PRICE = 1 ether;
    uint256 constant EXPECTED_ROYALTY = (SALE_PRICE * ROYALTY_FRACTION) / 10000; // 0.05 ETH

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

    function test_should_support_eip2981_interface() public {
        bytes4 interfaceId = 0x2a55205a; // EIP-2981 interface ID
        assertTrue(singletonFreeMint.supportsInterface(interfaceId));
    }

    function test_should_set_token_royalty() public {
        vm.startPrank(deployer);

        singletonFreeMint.setTokenRoyalty(1, royaltyReceiver, ROYALTY_FRACTION);
        
        (address receiver, uint256 royaltyAmount) = singletonFreeMint.royaltyInfo(1, SALE_PRICE);
        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, EXPECTED_ROYALTY);

        vm.stopPrank();
    }

    function test_should_emit_event_when_setting_royalty() public {
        vm.startPrank(deployer);

        vm.expectEmit(true, false, false, true);
        emit RoyaltyInfoUpdated(1, royaltyReceiver, ROYALTY_FRACTION);
        singletonFreeMint.setTokenRoyalty(1, royaltyReceiver, ROYALTY_FRACTION);

        vm.stopPrank();
    }

    function test_should_revert_when_setting_invalid_royalty_fraction() public {
        vm.startPrank(deployer);

        vm.expectRevert(FreeMintRegistry.InvalidInput.selector);
        singletonFreeMint.setTokenRoyalty(1, royaltyReceiver, 10001); // > 100%

        vm.stopPrank();
    }

    function test_should_revert_when_setting_zero_address_receiver() public {
        vm.startPrank(deployer);

        vm.expectRevert(FreeMintRegistry.InvalidInput.selector);
        singletonFreeMint.setTokenRoyalty(1, address(0), ROYALTY_FRACTION);

        vm.stopPrank();
    }

    function test_should_revert_when_non_owner_sets_royalty() public {
        vm.startPrank(unauthorizedUser);

        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.setTokenRoyalty(1, royaltyReceiver, ROYALTY_FRACTION);

        vm.stopPrank();
    }

    function test_should_return_zero_royalty_for_unset_token() public {
        (address receiver, uint256 royaltyAmount) = singletonFreeMint.royaltyInfo(999, SALE_PRICE);
        assertEq(receiver, address(0));
        assertEq(royaltyAmount, 0);
    }

    function test_should_calculate_royalty_correctly_for_different_prices() public {
        vm.startPrank(deployer);
        singletonFreeMint.setTokenRoyalty(1, royaltyReceiver, ROYALTY_FRACTION);
        vm.stopPrank();

        // Test with 1 ETH
        (,uint256 royaltyAmount1) = singletonFreeMint.royaltyInfo(1, 1 ether);
        assertEq(royaltyAmount1, (1 ether * ROYALTY_FRACTION) / 10000);

        // Test with 0.5 ETH
        (,uint256 royaltyAmount2) = singletonFreeMint.royaltyInfo(1, 0.5 ether);
        assertEq(royaltyAmount2, (0.5 ether * ROYALTY_FRACTION) / 10000);

        // Test with 2 ETH
        (,uint256 royaltyAmount3) = singletonFreeMint.royaltyInfo(1, 2 ether);
        assertEq(royaltyAmount3, (2 ether * ROYALTY_FRACTION) / 10000);
    }

    function test_should_allow_updating_existing_royalty() public {
        vm.startPrank(deployer);
        
        // Set initial royalty
        singletonFreeMint.setTokenRoyalty(1, royaltyReceiver, ROYALTY_FRACTION);
        
        // Update to new values
        address newReceiver = address(0x123);
        uint96 newFraction = 1000; // 10%
        
        singletonFreeMint.setTokenRoyalty(1, newReceiver, newFraction);
        
        (address receiver, uint256 royaltyAmount) = singletonFreeMint.royaltyInfo(1, SALE_PRICE);
        assertEq(receiver, newReceiver);
        assertEq(royaltyAmount, (SALE_PRICE * newFraction) / 10000);
        
        vm.stopPrank();
    }

    function test_should_handle_zero_sale_price() public {
        vm.startPrank(deployer);
        singletonFreeMint.setTokenRoyalty(1, royaltyReceiver, ROYALTY_FRACTION);
        vm.stopPrank();

        (address receiver, uint256 royaltyAmount) = singletonFreeMint.royaltyInfo(1, 0);
        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, 0);
    }

    function test_should_handle_minimum_royalty_fraction() public {
        vm.startPrank(deployer);
        
        uint96 minFraction = 1; // 0.01%
        singletonFreeMint.setTokenRoyalty(1, royaltyReceiver, minFraction);
        
        (address receiver, uint256 royaltyAmount) = singletonFreeMint.royaltyInfo(1, SALE_PRICE);
        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, (SALE_PRICE * minFraction) / 10000);
        
        vm.stopPrank();
    }

    function test_should_handle_maximum_royalty_fraction() public {
        vm.startPrank(deployer);
        
        uint96 maxFraction = 10000; // 100%
        singletonFreeMint.setTokenRoyalty(1, royaltyReceiver, maxFraction);
        
        (address receiver, uint256 royaltyAmount) = singletonFreeMint.royaltyInfo(1, SALE_PRICE);
        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, SALE_PRICE); // Full amount
        
        vm.stopPrank();
    }
}
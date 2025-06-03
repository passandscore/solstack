// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {FreeMintRegistry} from "src/upgradeable/FreeMintRegistry.sol";

contract FreeMintRegistry_AdminMint is ContractUnderTest {
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
            uint32(block.timestamp + 1 days)
        );
        vm.stopPrank();
    }

    function test_should_batch_admin_mint() public {
        vm.startPrank(deployer);
        
        address[] memory recipients = new address[](3);
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = user3;

        uint256[] memory quantities = new uint256[](3);
        quantities[0] = 5;
        quantities[1] = 3;
        quantities[2] = 2;

        singletonFreeMint.batchAdminMint(1, recipients, quantities);
        
        assertEq(singletonFreeMint.balanceOf(user1, 1), 5);
        assertEq(singletonFreeMint.balanceOf(user2, 1), 3);
        assertEq(singletonFreeMint.balanceOf(user3, 1), 2);
        assertEq(singletonFreeMint.totalTokensMinted(), 10);
    }

    function test_should_revert_when_unauthorized() public {
        vm.startPrank(unauthorizedUser);
        
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        uint256[] memory quantities = new uint256[](1);
        quantities[0] = 5;

        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.batchAdminMint(1, recipients, quantities);
    }

    function test_should_batch_admin_mint_when_paused() public {
        vm.startPrank(deployer);
        singletonFreeMint.pauseMint(1);
        
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory quantities = new uint256[](2);
        quantities[0] = 3;
        quantities[1] = 2;

        singletonFreeMint.batchAdminMint(1, recipients, quantities);
        
        assertEq(singletonFreeMint.balanceOf(user1, 1), 3);
        assertEq(singletonFreeMint.balanceOf(user2, 1), 2);
        assertEq(singletonFreeMint.totalTokensMinted(), 5);
    }

    function test_should_revert_when_arrays_length_mismatch() public {
        vm.startPrank(deployer);
        
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory quantities = new uint256[](1);
        quantities[0] = 5;

        vm.expectRevert(FreeMintRegistry.InvalidInput.selector);

        singletonFreeMint.batchAdminMint(1, recipients, quantities);
    }
} 

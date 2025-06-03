// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {FreeMintRegistry} from "contracts/upgradeable/FreeMintRegistry.sol";

contract FreeMintRegistry_UpdateMetadata is ContractUnderTest {
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

    function test_should_update_asset_uri() public {
        vm.startPrank(deployer);
        singletonFreeMint.setAssetURI(1, "ipfs://updated");
        vm.stopPrank();

        FreeMintRegistry.Freemint memory freemint = singletonFreeMint.getFreemintDetails(1);
        assertEq(freemint.assetURI, "ipfs://updated");
    }

    function test_should_revert_when_non_owner_updates_asset_uri() public {
        vm.startPrank(unauthorizedUser);
        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.setAssetURI(1, "ipfs://updated");
        vm.stopPrank();
    }

    function test_should_update_metadata() public {
        vm.startPrank(deployer);
        
        singletonFreeMint.updateMetadata(
            1,
            "Updated NFT",
            "Updated Artist",
            "Updated Description"
        );

        vm.stopPrank();

        FreeMintRegistry.Freemint memory freemint = singletonFreeMint.getFreemintDetails(1);
    
        assertEq(freemint.nftName, "Updated NFT");
        assertEq(freemint.artistName, "Updated Artist");
        assertEq(freemint.description, "Updated Description");
    }

    function test_should_revert_when_non_owner_updates_metadata() public {
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.updateMetadata(
            1,
            "Updated NFT",
            "Updated Artist",
            "Updated Description"
        );

        vm.stopPrank();
    }
} 
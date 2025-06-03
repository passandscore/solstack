// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {FreeMintRegistry} from "contracts/upgradeable/FreeMintRegistry.sol";

contract FreeMintRegistry_RegisterFreemint is ContractUnderTest {
    function setUp() public override {
        super.setUp();
    }

    function test_should_register_freemint() public {
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

        // Get freemint details
        FreeMintRegistry.Freemint memory freemint = singletonFreeMint.getFreemintDetails(1);
        
        assertEq(freemint.id, 1);
        assertEq(freemint.nftName, "Test NFT");
        assertEq(freemint.assetURI, "ipfs://test");
        assertEq(freemint.artistName, "Test Artist");
        assertEq(freemint.description, "Test Description");
        assertEq(freemint.mintStartTime, uint32(block.timestamp));
        assertEq(freemint.mintEndTime, uint32(block.timestamp + 1 days));
        assertEq(freemint.mintingPaused, false);
        assertEq(freemint.mintedSupply, 0);
    }

    function test_should_revert_when_unauthorized() public {
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert("Ownable: caller is not the owner");
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
    }
} 
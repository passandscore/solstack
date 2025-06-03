// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {FreeMintRegistry} from "contracts/upgradeable/FreeMintRegistry.sol";

contract FreeMintRegistry_MintControl is ContractUnderTest {
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

    function test_should_pause_mint() public {
        vm.startPrank(deployer);

        singletonFreeMint.pauseMint(1);
        assertTrue(singletonFreeMint.isPaused(1));

        vm.stopPrank();
    }

    function test_should_resume_mint() public {
        vm.startPrank(deployer);

        singletonFreeMint.pauseMint(1);
        singletonFreeMint.resumeMint(1);
       
        assertFalse(singletonFreeMint.isPaused(1));
        vm.stopPrank();
    }

    function test_should_update_mint_duration() public {
        vm.startPrank(deployer);

        uint32 newStartTime = uint32(block.timestamp + 1 days);
        uint32 newEndTime = uint32(block.timestamp + 2 days);

        singletonFreeMint.updateMintDuration(1, newStartTime, newEndTime);

        FreeMintRegistry.Freemint memory freemint = singletonFreeMint
            .getFreemintDetails(1);

        assertEq(freemint.mintStartTime, newStartTime);
        assertEq(freemint.mintEndTime, newEndTime);

        vm.stopPrank();
    }

    function test_should_revert_when_updating_nonexistent_freemint() public {
        vm.startPrank(deployer);

        vm.expectRevert(FreeMintRegistry.FreemintDoesNotExist.selector);
        singletonFreeMint.updateMintDuration(
            999,
            uint32(block.timestamp),
            uint32(block.timestamp + 1 days)
        );

        vm.stopPrank();
    }

    function test_should_revert_when_non_owner_controls_mint() public {
        vm.startPrank(unauthorizedUser);

        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.pauseMint(1);

        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.resumeMint(1);

        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.updateMintDuration(
            1,
            uint32(block.timestamp),
            uint32(block.timestamp + 1 days)
        );

        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.setAssetURI(1, "ipfs://updated");

        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.updateMetadata(
            1,
            "Updated NFT",
            "Updated Artist",
            "Updated Description"
        );

        vm.stopPrank();
    }

    function test_should_update_mint_price() public {
        vm.startPrank(deployer);
        singletonFreeMint.updateMintPrice(1, 1 ether);
        assertEq(singletonFreeMint.getMintPrice(1), 1 ether);
        vm.stopPrank();
    }

    function test_should_revert_when_updating_mint_price_of_nonexistent_freemint() public {
        vm.startPrank(deployer);

        vm.expectRevert(FreeMintRegistry.FreemintDoesNotExist.selector);
        singletonFreeMint.updateMintPrice(999, 1 ether);
    }

    function test_should_revert_when_non_owner_updates_mint_price() public {
        vm.startPrank(unauthorizedUser);

        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.updateMintPrice(1, 1 ether);
    }
}

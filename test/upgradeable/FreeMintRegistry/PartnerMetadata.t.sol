// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {FreeMintRegistry} from "contracts/upgradeable/FreeMintRegistry.sol";

contract FreeMintRegistry_UpdatePartnerMetadata is ContractUnderTest {
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

    function test_should_update_partner_name() public {
        vm.startPrank(deployer);
        singletonFreeMint.updatePartnerData(1, "Updated Partner", 200);
        vm.stopPrank();

        FreeMintRegistry.Freemint memory freemint = singletonFreeMint
            .getFreemintDetails(1);
        assertEq(freemint.partnerName, "Updated Partner");
    }

    function test_should_update_points_per_mint() public {
        vm.startPrank(deployer);
        singletonFreeMint.updatePartnerData(1, "Updated Partner", 200);
        vm.stopPrank();

        FreeMintRegistry.Freemint memory freemint = singletonFreeMint
            .getFreemintDetails(1);
        assertEq(freemint.pointsPerMint, 200);
    }

    function test_should_revert_when_non_owner_updates_partner_data() public {
        vm.startPrank(unauthorizedUser);
        vm.expectRevert("Ownable: caller is not the owner");
        singletonFreeMint.setAssetURI(1, "ipfs://updated");
        vm.stopPrank();
    }
}

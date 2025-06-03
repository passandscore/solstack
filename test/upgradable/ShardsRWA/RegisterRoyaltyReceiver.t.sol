// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import {CustomErrors} from "src/upgradable/ShardsRWA/CustomErrors.sol";
import {StorageSlots}  from "src/upgradable/ShardsRWA/ContractState.sol";

contract ERC721Core_RegisterRoyaltyReceiver is ContractUnderTest {
    string newNftName = "fractional.art";

    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_called_by_non_authorized_caller()
        external
    {
        vm.startPrank(unauthorizedUser);

        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));
        shardsRWA.registerRoyaltyReceiver(royaltyReceiver, 10000, 400);
    }

    function test_should_set_royalityReceiver() external {
        vm.startPrank(deployer);

        vm.assertEq(shardsRWA.royaltyReceiver(), royaltyReceiver);
        vm.assertEq(shardsRWA.primarySalePercentage(), 10000);
        vm.assertEq(shardsRWA.secondarySalePercentage(), 500);

        shardsRWA.registerRoyaltyReceiver(royaltyReceiver, 10000, 400);


        vm.assertEq(shardsRWA.royaltyReceiver(), royaltyReceiver);
        vm.assertEq(
            shardsRWA.primarySalePercentage(),
            10000
        );
        vm.assertEq(
            shardsRWA.secondarySalePercentage(),
            400
        );
    }

    function test_should_revert_when_secondarySalePercentage_is_out_of_range()
        external
    {
        vm.startPrank(deployer);

        vm.expectRevert(CustomErrors.SecondarySalePercentageOutOfRange.selector);
        shardsRWA.registerRoyaltyReceiver(royaltyReceiver, 10000, 10001);
    }

    function test_should_revert_when_primarySalePercentage_is_not_equal_to_max()
        external
    {
        vm.startPrank(deployer);

        vm.expectRevert(CustomErrors.PrimarySalePercentageNotEqualToMax.selector);
        shardsRWA.registerRoyaltyReceiver(royaltyReceiver, 9999, 400);
    }
}

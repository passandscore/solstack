// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";

contract ERC721Core_SetArtistName is ContractUnderTest {
    string newArtistName = "some artist";

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

        shardsRWA.setArtistName(newArtistName);
    }

    function test_should_set_artist_name() external {
        vm.startPrank(deployer);
        shardsRWA.setArtistName(newArtistName);

        vm.assertEq(shardsRWA.artistName(), newArtistName);
    }
}

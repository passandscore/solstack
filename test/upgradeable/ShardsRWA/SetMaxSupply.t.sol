// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";

contract ERC721Core_SetMaxSupply is ContractUnderTest {
    uint256 newMaxSupply = 100000;

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

        shardsRWA.setMaxSupply(newMaxSupply);
    }

    function test_should_set_max_supply() external {
        vm.assertEq(shardsRWA.maxSupply(), 50000);

        vm.startPrank(deployer);
        shardsRWA.setMaxSupply(newMaxSupply);

        vm.assertEq(shardsRWA.maxSupply(), newMaxSupply);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";

contract ERC721Core_SetMintingWindow is ContractUnderTest {
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

        uint32 startTime = uint32(block.timestamp - 1);
        uint32 endTime = uint32(block.timestamp + 1 days);
        shardsRWA.setMintDuration(startTime, endTime);
    }

    function test_should_set_minting_window() external {
        vm.startPrank(deployer);
        uint32 start = uint32(block.timestamp - 1);
        uint32 end = uint32(block.timestamp + 1 days);
        shardsRWA.setMintDuration(start, end);

        (uint32 startTime, uint32 endTime)  = shardsRWA.getMintingDuration();
        vm.assertEq(startTime, start);
        vm.assertEq(endTime, end);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/proxy/utils/Initializable.sol";


contract UserEngagementRegistry_Initialize is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
        vm.startPrank({msgSender: deployer});
    }

    function test_should_set_owner() external view {
        assertEq(userEngagementRegistry.owner(), address(deployer));
    }

    function test_should_revert_when_already_initialized() external {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        userEngagementRegistry.initialize();
    }
}

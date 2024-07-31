// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {UserEngagementRegistry} from "../../../src/upgradable/UserEngagementRegistry.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";

contract UserEngagementRegistry_ToggleGameStatus is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function RegisterNewGame() internal {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        vm.stopPrank();
    }

    function test_should_revert_when_game_does_not_exist() external {
        RegisterNewGame();

        vm.startPrank(deployer);
        vm.expectRevert(UserEngagementRegistry.GameDoesNotExist.selector);
        userEngagementRegistry.toggleGameStatus(2);
    }

    function test_should_revert_when_caller_is_not_owner() external {
        RegisterNewGame();

        vm.startPrank(user1);
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));
        userEngagementRegistry.toggleGameStatus(1);
    }

    function test_should_return_true_when_game_is_active() external {
        RegisterNewGame();

        vm.startPrank(deployer);
        assertEq(userEngagementRegistry.getGameStatus(1), true);
    }

    function test_should_return_false_when_game_is_inactive() external {
        RegisterNewGame();

        vm.startPrank(deployer);
        userEngagementRegistry.toggleGameStatus(1);
        assertEq(userEngagementRegistry.getGameStatus(1), false);
    }
}

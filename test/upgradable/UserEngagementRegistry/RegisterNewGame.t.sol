// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {UserEngagementRegistry} from "../../../src/upgradable/UserEngagementRegistry.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";

contract UserEngagementRegistry_RegisterNewGame is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_already_caller_is_not_owner() external {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        userEngagementRegistry.registerNewGame("game1");
    }

    function test_should_revert_when_game_already_exists() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        vm.expectRevert(UserEngagementRegistry.GameAlreadyExists.selector);
        userEngagementRegistry.registerNewGame("game1");
    }

    function test_should_revert_when_game_name_is_empty() external {
        vm.expectRevert(UserEngagementRegistry.InvalidInput.selector);
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("");
    }

    function test_total_games_should_increment_when_new_game_registered()
        external
    {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        assertEq(userEngagementRegistry.totalGames(), 1);
    }

    function test_game_stats_should_be_initialized_when_registered() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        uint256 gameId = userEngagementRegistry.getGameIdByName("game1");

        UserEngagementRegistry.GameStats
            memory gameStats = userEngagementRegistry.getGameStats(gameId);

        assertEq(gameStats.totalInteractions, 0);
        assertEq(gameStats.isGameActive, true);
        assertEq(gameStats.gameName, "game1");
    }

    function test_should_set_gameNameById_mapping_when_new_game_registered()
        external
    {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");

        uint256 gameId = userEngagementRegistry.getGameIdByName("game1");
        assertEq(userEngagementRegistry.getGameNameById(gameId), "game1");
    }
}

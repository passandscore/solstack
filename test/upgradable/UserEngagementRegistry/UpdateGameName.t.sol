// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {UserEngagementRegistry} from "../../../src/upgradable/UserEngagementRegistry.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";


contract UserEngagementRegistry_UpdateGameName is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_caller_is_not_owner() external {
        vm.startPrank(user1);
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, user1));
        userEngagementRegistry.updateGameName(1, "game1");
    }

    function test_should_revert_when_GameDoesNotExist() external {
        vm.startPrank(deployer);
        vm.expectRevert(UserEngagementRegistry.GameDoesNotExist.selector);
        userEngagementRegistry.updateGameName(1, "game1");
    }

    function test_should_revert_when_updating_game_name_to_existing_game_name()
        external
    {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        vm.expectRevert(UserEngagementRegistry.GameAlreadyExists.selector);
        userEngagementRegistry.updateGameName(1, "game1");
    }

    function test_should_update_game_name() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        uint256 gameIdBefore = userEngagementRegistry.getGameIdByName("game1");

        userEngagementRegistry.updateGameName(gameIdBefore, "game2");

        uint256 gameIdAfter = userEngagementRegistry.getGameIdByName("game2");
        UserEngagementRegistry.GameStats
            memory gameStats = userEngagementRegistry.getGameStats(gameIdAfter);

        assertEq(gameStats.gameName, "game2");
    }

    function test_should_update_gameStats_when_game_name_is_updated() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        uint256 gameIdBefore = userEngagementRegistry.getGameIdByName("game1");

        userEngagementRegistry.updateGameName(gameIdBefore, "game2");

        uint256 gameIdAfter = userEngagementRegistry.getGameIdByName("game2");
        UserEngagementRegistry.GameStats
            memory gameStats = userEngagementRegistry.getGameStats(gameIdAfter);

        assertEq(gameStats.gameName, "game2");
        assertEq(gameStats.gameId, gameIdAfter);
        assertEq(gameStats.totalInteractions, 0);
        assertTrue(gameStats.isGameActive);
    }

    function test_should_update_GetNameById_mapping() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        uint256 gameIdBefore = userEngagementRegistry.getGameIdByName("game1");

        userEngagementRegistry.updateGameName(gameIdBefore, "game2");

        uint256 gameIdAfter = userEngagementRegistry.getGameIdByName("game2");

        assertEq(gameIdAfter, gameIdBefore);
    }
}

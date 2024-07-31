// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {UserEngagementRegistry} from "../../../src/upgradable/UserEngagementRegistry.sol";

contract UserEngagementRegistry_UserInteraction is ContractUnderTest {
      event UserInteraction(
        uint256 indexed gameId,
        address indexed user,
        uint256 timestamp
    );
    
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_game_not_found() external {
        vm.startPrank(deployer);
        vm.expectRevert(UserEngagementRegistry.GameDoesNotExist.selector);
        userEngagementRegistry.userInteraction(1);
    }

    function test_should_revert_when_game_is_not_active() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");

        uint256 gameId = userEngagementRegistry.getGameIdByName("game1");
        userEngagementRegistry.toggleGameStatus(gameId);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(UserEngagementRegistry.GameNotActive.selector);
        userEngagementRegistry.userInteraction(gameId);
    }

    function test_should_update_userInteraction_count_for_game() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        userEngagementRegistry.registerNewGame("game2");
        vm.stopPrank();

        uint256 gameId1 = userEngagementRegistry.getGameIdByName("game1");

        // Test for game1
        vm.startPrank(user1);
        userEngagementRegistry.userInteraction(gameId1);
        uint256 userInteractionCountGame1 = userEngagementRegistry.getUserInteractionCountByGame(gameId1, user1);
        assertEq(userInteractionCountGame1, 1);

        // Test for game2
        uint256 gameId2 = userEngagementRegistry.getGameIdByName("game2");
        userEngagementRegistry.userInteraction(gameId2);
        uint256 userInteractionCountGame2 = userEngagementRegistry.getUserInteractionCountByGame(gameId2, user1);
        assertEq(userInteractionCountGame2, 1);

    }

    function test_should_update_totalInteraction_count_for_registry() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        userEngagementRegistry.registerNewGame("game2");
        vm.stopPrank();

        uint256 gameId1 = userEngagementRegistry.getGameIdByName("game1");
        uint256 gameId2 = userEngagementRegistry.getGameIdByName("game2");

        vm.startPrank(user1);
        userEngagementRegistry.userInteraction(gameId1);
        userEngagementRegistry.userInteraction(gameId2);
        uint256 totalInteractions = userEngagementRegistry.totalInteractions();
        assertEq(totalInteractions, 2);
    }

    function test_should_update_userInteractions_for_gamestats() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        userEngagementRegistry.registerNewGame("game2");
        vm.stopPrank();

        uint256 gameId1 = userEngagementRegistry.getGameIdByName("game1");
        uint256 gameId2 = userEngagementRegistry.getGameIdByName("game2");

        vm.startPrank(user1);
        userEngagementRegistry.userInteraction(gameId1);
        userEngagementRegistry.userInteraction(gameId2);

        uint256 userInteractionsGame1 = userEngagementRegistry.getGameStats(gameId1).totalInteractions;
        uint256 userInteractionsGame2 = userEngagementRegistry.getGameStats(gameId2).totalInteractions;

        assertEq(userInteractionsGame1, 1);
        assertEq(userInteractionsGame2, 1);


    }

    function test_should_emit_UserInteraction_event() external {
        vm.startPrank(deployer);
        userEngagementRegistry.registerNewGame("game1");
        vm.stopPrank();

        uint256 gameId1 = userEngagementRegistry.getGameIdByName("game1");

        vm.startPrank(user1);
        vm.expectEmit();
        emit UserInteraction(gameId1, user1, block.timestamp);
         userEngagementRegistry.userInteraction(gameId1);
    }

}

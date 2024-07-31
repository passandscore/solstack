// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/proxy/utils/Initializable.sol";

/**
 * @title UserEngagementRegistry
 * @dev Contract to track user engagement with web3 games
 * 
 * The contract allows game developers to register their games and track user interactions.
 * Game developers can register new games, update game names, toggle game status, and get game stats.
 * Users can interact with games and the contract tracks the total interactions across all games.
 */
contract UserEngagementRegistry is Initializable, OwnableUpgradeable {
    // =============================================================
    //                         EVENTS
    // =============================================================

    /// @dev emitted when a user interacts with a game
    event UserInteraction(
        uint256 indexed gameId,
        address indexed user,
        uint256 timestamp
    );

    // =============================================================
    //                         ERROR MESSAGES
    // =============================================================

    /// @dev triggered when a game already exists
    error GameAlreadyExists();

    /// @dev triggered when a game does not exist
    error GameDoesNotExist();

    /// @dev triggered when a game is not active
    error GameNotActive();

    /// @dev triggered when an invalid input is provided
    error InvalidInput();

    // =============================================================
    //                         STATE VARIABLES
    // =============================================================

    /**
     * @dev GameStats struct
     * gameId: Unique identifier for the game
     * totalInteractions: Total interactions with the game
     * gameName: Name of the game
     * isGameActive: Status of the game (active or inactive)
     *
     * @dev 255 bits available as the bool `isGameActive` is 1 bit. This allows for additional fields to be added in the future during upgrades if required.
     */

    struct GameStats {
        uint256 gameId;
        uint256 totalInteractions;
        string gameName;
        bool isGameActive;
    }

    /// @dev mapping of game stats by game name
    mapping(string => GameStats) private gameStatsByGameName;

    /// @dev mapping of game name by game id
    mapping(uint256 => string) private gameNameByGameId;

    /// @dev mapping of user interactions by game id
    mapping(address => mapping(uint256 => uint256))
        private userInteractionsByGameId;

    /// @dev total games registered
    uint256 public totalGames;

    /// @dev total interactions across all games
    uint256 public totalInteractions;

    // =============================================================
    //                         INITIALIZER
    // =============================================================

    /**
     * @dev Initialize the contract
     * @notice To be called once during contract deployment
     */
    function initialize() public initializer {
         __Ownable_init(msg.sender);
    }

    // =============================================================
    //                         USER METHODS
    // =============================================================

    /**
     * @dev User interaction with a game
     * @param _gameId Game id
     *
     * Requirements:
     * - Game should exist
     * - Game should be active
     */
    function userInteraction(uint256 _gameId) public {
        address user = msg.sender;

        GameStats storage existingGame = _fetchExistingGame(_gameId);

        _requireGameExists(existingGame.gameId);

        if (!existingGame.isGameActive) {
            revert GameNotActive();
        }

        userInteractionsByGameId[user][_gameId] += 1;
        existingGame.totalInteractions += 1;
        totalInteractions += 1;

        emit UserInteraction(_gameId, user, block.timestamp);
    }

    // =============================================================
    //                         OWNER METHODS
    // =============================================================

    /**
     * @dev Register a new game
     * @param _gameName Name of the game
     *
     * Requirements:
     * - Game should not already exist
     * - Caller should be the owner
     */
    function registerNewGame(string memory _gameName) external onlyOwner {
        
        if(bytes(_gameName).length == 0) {
            revert InvalidInput();
        }

        _requireUniqueGameName(_gameName);

        totalGames += 1;
        GameStats storage newGame = gameStatsByGameName[_gameName];

        newGame.gameId = totalGames;
        newGame.gameName = _gameName;
        newGame.isGameActive = true;

        gameNameByGameId[totalGames] = _gameName;
    }

    /**
     * @dev Update game name
     * @param _gameId Game id
     * @param _newGameName New game name
     *
     * Requirements:
     * - Game should exist
     * - New game name should not already exist
     */
    function updateGameName(
        uint256 _gameId,
        string memory _newGameName
    ) external onlyOwner {
        GameStats storage existingGame = _fetchExistingGame(_gameId);

        _requireGameExists(_gameId);
        _requireUniqueGameName(_newGameName);

        // Update game name mapping
        existingGame.gameName = _newGameName;
        gameStatsByGameName[_newGameName] = existingGame;

        // Remove the old gameStats struct from the mapping
        delete existingGame.gameId;
        delete existingGame.gameName;
        delete existingGame.totalInteractions;
        delete existingGame.isGameActive;

        // Update game name by game ID mapping
        gameNameByGameId[_gameId] = _newGameName;
    }

    /**
     * @dev Toggle game status
     * @param _gameId Game id
     *
     * Requirements:
     * - Game should exist
     */
    function toggleGameStatus(uint256 _gameId) external onlyOwner {
        GameStats storage existingGame = _fetchExistingGame(_gameId);
        _requireGameExists(existingGame.gameId);

        existingGame.isGameActive = !existingGame.isGameActive;
    }

    // =============================================================
    //                         VIEW METHODS
    // =============================================================

    /**
     * @dev Get user interaction count by game
     * @param _gameId Game id
     * @return User interaction count as a uint256
     */
    function getUserInteractionCountByGame(
        uint256 _gameId,
        address _user
    ) external view returns (uint256) {
        return userInteractionsByGameId[_user][_gameId];
    }

    /**
     * @dev Get game stats
     * @param _gameId Game id
     * @return GameStats struct
     */
    function getGameStats(
        uint256 _gameId
    ) external view returns (GameStats memory) {
        return _fetchExistingGame(_gameId);
    }

    /**
     * @dev Get game id by name
     * @param _gameName Game name
     * @return Game id as a uint256
     */
    function getGameIdByName(
        string memory _gameName
    ) external view returns (uint256) {
        return gameStatsByGameName[_gameName].gameId;
    }

    /**
     * @dev Get game name by id
     * @param _gameId Game id
     * @return Game name as a string
     */
    function getGameNameById(
        uint256 _gameId
    ) external view returns (string memory) {
        return gameNameByGameId[_gameId];
    }

    /**
     * @dev Get game status
     * @param _gameId Game id
     * @return Game status (active or inactive) as a boolean
     */
    function getGameStatus(uint256 _gameId) external view returns (bool) {
        GameStats memory existingGame = _fetchExistingGame(_gameId);
        return existingGame.isGameActive;
    }

    // =============================================================
    //                         INTERNAL METHODS
    // =============================================================

    /**
     * @dev Require game exists
     * @param _gameId Game id
     */
    function _requireGameExists(uint256 _gameId) internal pure {
        if (_gameId == 0) {
            revert GameDoesNotExist();
        }
    }

    /**
     * @dev Require unique game name
     * @param _gameName Game name
     */
    function _requireUniqueGameName(string memory _gameName) internal view {
        if (bytes(gameStatsByGameName[_gameName].gameName).length != 0) {
            revert GameAlreadyExists();
        }
    }

    /**
     * @dev Fetch existing game
     * @param _gameId Game id
     * @return GameStats struct
     */
    function _fetchExistingGame(uint256 _gameId) internal view returns (GameStats storage) {
        string memory gameName = gameNameByGameId[_gameId];
        return gameStatsByGameName[gameName];
    }
}

# Function Breakdown

### Initializer

- **initialize**
  - **Purpose**: Initializes the contract and sets the initial owner.
  - **Access**: External
  - **Modifiers**: `initializer`
  - **Usage**: Sets up the contract with initial parameters upon deployment.

### User Interaction

- **userInteraction**
  - **Purpose**: Records a user's interaction with a specified game.
  - **Access**: Public
  - **Parameters**:
    - `gameId`: The ID of the game being interacted with.
  - **Usage**: Tracks and updates the number of interactions for the specified game and user.

### Game Management

- **registerNewGame**
  - **Purpose**: Registers a new game in the system.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Parameters**:
    - `gameName`: The name of the game to be registered.
  - **Usage**: Adds a new game to the system, allowing it to be tracked for user interactions.

- **updateGameName**
  - **Purpose**: Updates the name of an existing game.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Parameters**:
    - `gameId`: The ID of the game to update.
    - `newGameName`: The new name for the game.
  - **Usage**: Changes the name of a registered game, ensuring the game's metadata is up-to-date.

- **toggleGameStatus**
  - **Purpose**: Activates or deactivates a game.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Parameters**:
    - `gameId`: The ID of the game to toggle.
  - **Usage**: Enables or disables a game's activity status, controlling whether it can receive interactions.

### View Functions

- **getUserInteractionCountByGame**
  - **Purpose**: Retrieves the number of interactions a user has had with a specific game.
  - **Access**: External
  - **Parameters**:
    - `gameId`: The ID of the game.
    - `user`: The address of the user.
  - **Returns**: The number of interactions by the user with the specified game.

- **getGameStats**
  - **Purpose**: Retrieves the statistics for a specific game.
  - **Access**: External
  - **Parameters**:
    - `gameId`: The ID of the game.
  - **Returns**: A `GameStats` struct containing details about the game.

- **getGameIdByName**
  - **Purpose**: Retrieves the ID of a game by its name.
  - **Access**: External
  - **Parameters**:
    - `gameName`: The name of the game.
  - **Returns**: The ID of the game.

- **getGameNameById**
  - **Purpose**: Retrieves the name of a game by its ID.
  - **Access**: External
  - **Parameters**:
    - `gameId`: The ID of the game.
  - **Returns**: The name of the game.

- **getGameStatus**
  - **Purpose**: Retrieves the status (active or inactive) of a game.
  - **Access**: External
  - **Parameters**:
    - `gameId`: The ID of the game.
  - **Returns**: A boolean indicating whether the game is active.

### Internal Functions

- **_requireGameExists**
  - **Purpose**: Ensures a game exists in the registry.
  - **Access**: Internal
  - **Parameters**:
    - `gameId`: The ID of the game.
  - **Usage**: Throws an error if the game does not exist.

- **_requireUniqueGameName**
  - **Purpose**: Ensures a game name is unique and not already used.
  - **Access**: Internal
  - **Parameters**:
    - `gameName`: The name of the game.
  - **Usage**: Throws an error if the game name is already taken.

- **_fetchExistingGame**
  - **Purpose**: Retrieves the details of an existing game by ID.
  - **Access**: Internal
  - **Parameters**:
    - `gameId`: The ID of the game.
  - **Returns**: A `GameStats` struct containing game details.

### Error Handling

- **GameAlreadyExists**
  - **Purpose**: Custom error thrown when attempting to register a game that already exists.

- **GameDoesNotExist**
  - **Purpose**: Custom error thrown when attempting to interact with or modify a non-existent game.

- **GameNotActive**
  - **Purpose**: Custom error thrown when attempting to interact with an inactive game.

- **InvalidInput**
  - **Purpose**: Custom error thrown when an invalid input is provided.

# UserEngagementRegistry

The `UserEngagementRegistry` contract allows game developers to register their games and track user interactions in web3 games. The contract supports an upgradeable design using an initializer function for deployment.

## Key Features

- **Contract Type**: upgradeable contract for tracking game interactions.
- **Initializer Function**: Initializes the contract and sets the initial owner.
- **Ownership**: Uses `OwnableUpgradeable` for access control.
- **Game Management**: Provides functions to register new games, update game names, and toggle game statuses.
- **User Interaction Tracking**: Records user interactions with games and maintains interaction counts.
- **Game Statistics**: Maintains game statistics including game ID, total interactions, game name, and active status.

## Error Handling

- `GameAlreadyExists`: Thrown when attempting to register a game that already exists.
- `GameDoesNotExist`: Thrown when attempting to interact with or modify a non-existent game.
- `GameNotActive`: Thrown when attempting to interact with an inactive game.
- `InvalidInput`: Thrown when an invalid input is provided.

## Usage

This contract allows game developers to manage game registrations and track user interactions. It provides a fair and transparent system for monitoring engagement in web3 games. Developers can use the data for analytics, rewards, or other engagement-driven functionalities.

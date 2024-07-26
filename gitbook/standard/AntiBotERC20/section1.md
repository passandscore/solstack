# How It Works
#### Buy Block Tracking:

The contract maintains a mapping called _buyBlock that stores the block number when a buy transaction occurs for each address.

#### Bot Check Logic:

The isBot modifier checks if the from address has the same block number stored in _buyBlock as the current block number.
If the from address has a buy transaction recorded in the same block, the transfer is flagged as "Bot blocked!" and blocked.
Before Token Transfer Hook:

The _requireBotCheck function is called before any token transfer, including transfer and transferFrom.
This function updates the _buyBlock mapping for the to address with the current block number.
Toggleable Bot Check:

The enableBotCheck variable can be toggled by the contract owner to enable or disable the bot-checking functionality.

## How It Prevents Attacks

Frontrunner bots typically buy and sell tokens within the same block to exploit price differences.
By recording the block number of buy transactions and checking it during subsequent transfers, the contract can identify and block transactions that occur within the same block.
This makes it difficult for bots to execute their typical buy-sell strategies within a single block, as any attempt to transfer tokens bought in the same block will be flagged and blocked.

## Detailed Explanation
#### Buy Block Recording:

- When a transfer occurs, the _requireBotCheck function is called.
- This function updates the _buyBlock mapping for the to address with the current block number.
- This means that whenever someone receives tokens, the block number of that transaction is recorded.

#### Bot Check:

- The isBot modifier is applied to the from address.
- Before any transfer is executed, the isBot modifier checks if the from address has a recorded block number that matches the current block number.
- If the from address has a buy transaction recorded in the same block, the transfer is flagged as "Bot blocked!" and blocked.
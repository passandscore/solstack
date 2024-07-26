# AntiBotERC20

Frontrunner bots typically buy and sell tokens within the same block to exploit price differences. By checking the from address during transfers, the AnitBotERC20 contract can effectively prevent frontrunner bots from executing buy and sell transactions within the same block. This approach ensures that any attempt to transfer tokens bought in the same block is flagged and blocked, making it difficult for bots to exploit price differences within a single block.

# Example Scenario
Bot Buys Tokens:

- A frontrunner bot buys tokens in block 100.
- The _buyBlock mapping for the bot's address is updated to 100.

Bot Attempts to Sell Tokens:

- In the same block (block 100), the bot attempts to sell the tokens.
- The isBot modifier checks the from address (the bot's address) and finds that _buyBlock[from] is equal to the current block number (100).
- The transfer is flagged as "Bot blocked!" and blocked.
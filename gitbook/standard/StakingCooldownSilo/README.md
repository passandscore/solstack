# Staking Cooldown Silo

The **Staking Cooldown Silo** contract securely stores staking tokens during the cooldown period required before tokens can be withdrawn from a staking contract. The cooldown period is a waiting period imposed after a user initiates an unstake operation, during which the tokens cannot be transferred or used.

This contract works in conjunction with a separate staking contract, which is responsible for managing all additional logic, such as initiating the cooldown period and validating withdrawals.

## Key Features

- **Token Storage:** Holds staking tokens while they are in the cooldown phase.
- **Controlled Withdrawals:** Only the associated staking contract can initiate withdrawals.

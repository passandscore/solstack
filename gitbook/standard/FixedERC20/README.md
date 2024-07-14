### Fixed ERC20 Token

The `FixedERC20` contract is an ERC20 token implementation with a fixed total supply and restricted minting capabilities. Key features include:

- **Minting and Burning**: Tokens can be minted and burned only by the contract owner.
- **No Minting Function**: The total token supply is minted during contract deployment and cannot be increased thereafter.

This contract ensures that once deployed, the token supply remains fixed, providing transparency and predictability for token holders and users.

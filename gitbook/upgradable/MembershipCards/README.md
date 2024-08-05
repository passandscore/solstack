# MembershipCards

The `MembershipCards` contract is an upgradable smart contract that allows users to mint membership cards during pre-sale and public mint phases. It features an initializer function for deployment, making it adaptable to future upgrades.

## Key Features

- **Contract Type**: Upgradable contract for minting membership cards.
- **Initializer Function**: Sets the initial parameters and owner of the contract.
- **Ownership**: Utilizes `OwnableUpgradeable` for access control.
- **Minting Phases**: Supports pre-sale and public mint phases with respective controls.
- **Trading Restrictions**: Provides the ability to restrict trading.
- **Airdrop Functionality**: Allows batch transfers of membership cards for airdrops.

## Error Handling

- `InsufficientEtherValue`: Thrown when the provided ether value is insufficient for the requested minting quantity.
- `InsufficientSupply`: Thrown when the requested quantity exceeds the maximum supply.
- `MaxMintPerAddressReached`: Thrown when the requested quantity exceeds the maximum allowed per wallet.
- `MintNotOpened`: Thrown when the minting phase is not active.
- `NotWhitelisted`: Thrown when the caller is not whitelisted for the pre-sale.
- `WithdrawlError`: Thrown when there is an issue with withdrawing funds.
- `TradingRestricted`: Thrown when trading is restricted.
- `IncorrectTokenIdsLength`: Thrown when the length of the token IDs and recipients arrays do not match.
- `TooManyRecipients`: Thrown when the recipients array exceeds the maximum batch size for airdrops.
- `NoRecipients`: Thrown when the recipients array is empty.

## Usage

This contract allows users to mint membership cards during designated phases and provides mechanisms for the owner to manage various aspects, such as mint prices, whitelist settings, and trading restrictions. The airdrop functionality facilitates batch transfers, making it useful for promotional activities.

The contract ensures a fair minting process with restrictions on the maximum number of cards per wallet and whitelist checks during the pre-sale phase. It also offers a secure way to handle ether transactions and withdrawals.

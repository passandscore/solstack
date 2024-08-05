# Function Breakdown

### Initializer

- **initialize**
  - **Purpose**: Initializes the contract and sets the initial owner.
  - **Access**: External
  - **Modifiers**: `initializer`
  - **Security**: Can only be called once, ensuring the contract is initialized correctly and securely.

### Contract Management

- **setMaxMintPerAddress**
  - **Purpose**: Sets the maximum number of membership cards that can be minted per address.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Only the contract owner can set limits, preventing unauthorized changes.

- **setMintStartTimestamp**
  - **Purpose**: Sets the timestamp when minting starts.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Restricted to the contract owner to prevent tampering with the minting schedule.

- **toggleMintOpened**
  - **Purpose**: Toggles the state of the minting process.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Controlled by the owner to prevent unauthorized enabling or disabling of minting.

- **toggleTradingRestricted**
  - **Purpose**: Toggles the restriction status for trading membership cards.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Only the owner can change trading status, ensuring secure control over trading permissions.

- **setWhitelistMerkleRoot**
  - **Purpose**: Sets the Merkle root for the whitelist.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: The owner controls the whitelist, preventing unauthorized access to the pre-sale.

- **setMaxSupply**
  - **Purpose**: Sets the maximum supply of membership cards.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Prevents exceeding the predefined maximum supply, ensuring scarcity.

- **setMintPrice**
  - **Purpose**: Sets the price for minting membership cards.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Only the owner can set prices, preventing arbitrary pricing changes.

- **setPreSaleStartTimestamp**
  - **Purpose**: Sets the timestamp for the start of the pre-sale.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Secured by owner control to ensure the correct timing of the pre-sale.

- **setPresaleMaxMintPerWallet**
  - **Purpose**: Sets the maximum number of cards that can be minted per wallet during the pre-sale.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Prevents abuse of the pre-sale by limiting the number of cards per wallet.

- **setBaseURI**
  - **Purpose**: Sets the base URI for the metadata.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Ensures that only the owner can change the base URI, maintaining the integrity of metadata links.

- **setAirdropMaxBatchSize**
  - **Purpose**: Sets the maximum batch size for airdrops.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Limits the number of airdropped cards to prevent misuse.

### Minting

- **mintPreSale**
  - **Purpose**: Mints membership cards during the pre-sale for whitelisted users.
  - **Access**: External
  - **Modifiers**: `whenPreSaleActive`
  - **Security**: Ensures only whitelisted addresses can participate, with checks for sufficient payment and supply.

- **publicMint**
  - **Purpose**: Mints membership cards during the public mint phase.
  - **Access**: External
  - **Modifiers**: `whenMintActive`
  - **Security**: Secured by checks for minting phase status, payment verification, and supply limits.

- **adminMint**
  - **Purpose**: Mints membership cards for a specified recipient.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Reserved for the owner to distribute cards as needed, with controlled issuance.

### Airdrops

- **batchTransfer**
  - **Purpose**: Transfers membership cards to multiple recipients in a batch.
  - **Access**: External
  - **Security**: Ensures controlled distribution, preventing oversupply or unauthorized transfers.

### View Functions

- **isPreSaleOpen**
  - **Purpose**: Checks if the pre-sale is open.
  - **Access**: Public
  - **Security**: Provides a read-only view of the pre-sale status.

- **balance**
  - **Purpose**: Returns the contract's balance.
  - **Access**: Public
  - **Security**: Read-only access to the contract's ether balance.

### ERC721 Overrides

- **tokenURI**
  - **Purpose**: Returns the metadata URI for a given token ID.
  - **Access**: Public
  - **Security**: Ensures correct metadata is linked to tokens, crucial for token information integrity.

### Withdrawals

- **withdrawAmount**
  - **Purpose**: Withdraws a specified amount from the contract balance.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Only the owner can withdraw funds, protecting against unauthorized access.

- **withdrawAll**
  - **Purpose**: Withdraws the entire contract balance.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Security**: Full balance withdrawal restricted to the owner, ensuring secure fund management.

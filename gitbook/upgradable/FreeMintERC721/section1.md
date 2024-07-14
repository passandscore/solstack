# Function Breakdown

### Initializer

- **initialize**
  - **Purpose**: Initializes the contract with name, symbol, and asset URI.
  - **Access**: External
  - **Modifiers**: `initializer`
  - **Parameters**:
    - `name`: Name of the ERC721 token.
    - `symbol`: Symbol of the ERC721 token.
    - `asset`: URI for the NFT asset.
  - **Usage**: Sets up the contract with initial parameters upon deployment.

### Mint Control

- **pauseMint**
  - **Purpose**: Pauses the minting of new tokens.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Usage**: Prevents new tokens from being minted temporarily.

- **resumeMint**
  - **Purpose**: Resumes minting of new tokens after pausing.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Usage**: Restores the ability to mint new tokens after a pause.

- **setMintDuration**
  - **Purpose**: Sets the window during which NFT minting is allowed.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Parameters**:
    - `startTime`: Start timestamp of the minting window.
    - `endTime`: End timestamp of the minting window.
  - **Usage**: Defines the period when users can mint NFTs.

### Minting

- **mint**
  - **Purpose**: Mints a new NFT to the caller if conditions are met.
  - **Access**: External
  - **Usage**: Allows each wallet to mint only one NFT during the specified minting window. Minting is free.

### Metadata Management

- **setAssetURI**
  - **Purpose**: Sets the URI for the NFT asset image.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Parameters**:
    - `assetURI`: URI for the NFT asset image.
  - **Usage**: Updates the location from which the NFT image can be retrieved.

- **setMetadataProperties**
  - **Purpose**: Sets the name, artist name, and description for NFT metadata.
  - **Access**: External
  - **Modifiers**: `onlyOwner`
  - **Parameters**:
    - `nftName`: Name of the NFT.
    - `artistName`: Name of the artist.
    - `description`: Description of the NFT.
  - **Usage**: Defines the textual properties associated with the NFT.

### View Functions

- **tokenURI**
  - **Purpose**: Retrieves the metadata URI for a given token ID.
  - **Access**: Public
  - **Overrides**: `ERC721Upgradeable`
  - **Parameters**:
    - `tokenId`: ID of the token to retrieve metadata for.
  - **Returns**: Metadata URI in JSON format containing token details.
  - **Usage**: Generates and returns a JSON string representing the NFT metadata.

### Internal Functions

- **_requireOpenMint**
  - **Purpose**: Checks if minting is currently allowed based on time and pause status.
  - **Access**: Internal
  - **Returns**: Boolean indicating if minting is allowed (`true`) or not (`false`).
  - **Usage**: Ensures minting can only occur during the specified window and when not paused.

### Error Handling

- **TokenNotFound**
  - **Purpose**: Custom error thrown when a requested token does not exist.

- **TokenAlreadyMinted**
  - **Purpose**: Custom error thrown when a user attempts to mint a token more than once.

- **MintingNotEnabled**
  - **Purpose**: Custom error thrown when minting is attempted outside of the specified window or while paused.

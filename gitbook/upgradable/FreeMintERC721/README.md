# FreeMintERC721

The `FreeMintERC721` contract manages free NFT minting with URI metadata generation. It supports an upgradable design using an initializer function for deployment.

## Key Features

- **Contract Type**: Upgradable ERC721 contract.
- **Initializer Function**: Initializes the contract with name, symbol, and asset URI.
- **Ownership**: Uses `OwnableUpgradeable` for access control.
- **Minting Control**: Provides functions to pause, resume, and set minting windows.
- **Token Ownership Limitation**: Allows only one token to be minted per wallet.
- **Token Minting Cost**: Minting in this contract is free of charge.
- **Token Metadata**: Generates JSON metadata URI including name, tokenId, image URI, artist name, and description.

## Error Handling

- `TokenNotFound`: Thrown when the token does not exist.
- `TokenAlreadyMinted`: Thrown when the caller has already minted a token.
- `MintingNotEnabled`: Thrown when minting is paused or outside the specified minting window.

## Usage

This contract allows controlled and free minting of NFTs with customizable metadata. Each wallet can mint only one token to ensure fairness and distribution control. There is no cost associated with minting tokens, making it accessible to all users.

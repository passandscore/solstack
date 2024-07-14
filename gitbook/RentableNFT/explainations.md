# RentableNFT

RentableNFT is a Solidity smart contract that extends `BasicERC721` and implements the `IERC4907` interface, enabling NFTs to be rented. This contract includes custom errors, events, state variables, and various functions to manage rentals, permissions, and revenues.

## Purpose

RentableNFT allows NFT owners to rent out their tokens to users for a specified period. The contract handles rental agreements, collects rental payments, and manages the distribution of rental revenue to the owners. It ensures secure and transparent rental transactions through various validations and permission checks.

## Functions

### setUser

- **Purpose**: Allows the owner or approved address to set a user and expiration for a permissioned rental.
- **Security**: Validates rental availability, user, and permissions. Ensures the caller is the owner or an approved address. Prevents setting a user for an already rented NFT or without proper permissions.

### rent

- **Purpose**: Enables a user to rent an NFT for a specified period.
- **Security**: Ensures the NFT is not currently rented under a permissioned agreement, validates the user and expiration, and requires sufficient payment. Reverts the transaction if these conditions are not met.

### userOf

- **Purpose**: Retrieves the current user address of a rented NFT.
- **Returns**: The user address if the rental is valid and ongoing, otherwise returns the zero address.

### userExpires

- **Purpose**: Gets the expiration timestamp of a rented NFT.
- **Returns**: The expiration timestamp to provide rental period information.

### withdrawRentalRevenue

- **Purpose**: Allows the owner to withdraw their accumulated rental revenue.
- **Security**: Ensures the caller has rental revenue to withdraw, reverts the transaction if there is no revenue.

### setRentalSpecs

- **Purpose**: Sets the rental specifications for all NFTs owned by the caller.
- **Security**: No additional checks needed as it pertains to the caller's own NFTs.

### setPermissionedRental

- **Purpose**: Sets the permissioned rental status of an NFT.
- **Security**: Validates the caller’s permissions before setting the status. Ensures only the owner or an approved address can set the status.

### getPermissionedRental

- **Purpose**: Retrieves the permissioned rental status of an NFT.
- **Returns**: The permissioned rental status.

### getRentalInfo

- **Purpose**: Retrieves the rental information of an NFT.
- **Returns**: The rental price, user address, and expiration timestamp.

### getRentalEstimate

- **Purpose**: Calculates the rental estimate for an NFT.
- **Returns**: The total days and rental price based on the provided expiration timestamp.

### getRentalSpecs

- **Purpose**: Retrieves the rental specifications of an NFT owner.
- **Returns**: The rental price per day and maximum rental days.

### unclaimedRevenueTotal

- **Purpose**: Gets the total unclaimed rental revenue of the caller.
- **Returns**: The total unclaimed revenue for withdrawal purposes.

## Required Overrides

### supportsInterface

- **Purpose**: Checks if the contract supports a given interface.
- **Returns**: True if the interface is supported, false otherwise.

### _burn

- **Purpose**: Destroys a token and clears its user information.
- **Security**: Validates rental availability before burning the token, ensuring the token is not rented.

### withdraw

- **Purpose**: Withdraws the contract balance to the owner.
- **Security**: Ensures the balance to withdraw is greater than 0 and calculates the amount based on total rental revenue.

## Internal Functions

### _requireRentalAvailable

- **Purpose**: Checks if the rental is available.
- **Security**: Prevents actions on already rented NFTs.

### _requireValidRental

- **Purpose**: Validates the user and expiration timestamp for a rental.
- **Security**: Ensures the user is valid and the expiration is in the future.

### _validatePermissions

- **Purpose**: Validates the caller’s permissions for a token.
- **Security**: Ensures only the owner or approved addresses can perform certain actions.

### _calculateRentalEstimate

- **Purpose**: Calculates the rental estimate based on the expiration timestamp.
- **Returns**: The total days of the rental and total rental price.

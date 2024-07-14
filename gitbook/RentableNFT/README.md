# RentableNFT Contract

RentableNFT is a Solidity smart contract that extends `BasicERC721` and implements the `IERC4907` interface, enabling NFTs to be rented. This contract includes custom errors, events, state variables, and various functions to manage rentals, permissions, and revenues.

## Purpose

RentableNFT allows NFT owners to rent out their tokens to users for a specified period. The contract handles rental agreements, collects rental payments, and manages the distribution of rental revenue to the owners. It ensures secure and transparent rental transactions through various validations and permission checks.
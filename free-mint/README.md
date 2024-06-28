# **FreeMint Contract**

**Free NFT Minting with URI Metadata Generation**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## **Overview**

**FreeMint** allows users to mint unique NFTs for free, with dynamic URI metadata generation. It’s built on the ERC721 standard using OpenZeppelin upgradeable contracts.

## **Features**

- **Free Minting:** Users can mint one NFT for free.
- **Pausing:** Contract owner can pause minting.
- **Dynamic Metadata:** Generates metadata for each NFT.
- **ERC721 Compliant:** Uses OpenZeppelin’s `ERC721Upgradeable`.


You will need a local fork of the Ethereum mainnet to run tests.

```bash
export MAINNET_RPC_URL=<your-mainnet-rpc-url>
```

```bash
make
```



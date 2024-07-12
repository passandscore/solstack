
<img src="logo.png" alt="logo" height="118"/>


An ever-growing stack of handcrafted Solidity examples. 

---

<details>
<summary>Quickstart Commands</summary>

Run this command to install dependencies, compile contracts, and execute all tests:

```bash
make
```

## Setting Up Environment Variables


Create a .env file in the project directory.


In the .env file, provide the following environment variable by replacing <url> with your  RPC URL. For example:


```bash
<YOUR_ENV_RPC_VARIABLE_NAME>=<url>
```


Running the Test Suite
Now that you've set up your environment variables, follow these steps to run the test suite:
In the terminal, run the following commands:

```bash
 source .env
 forge test --fork-url $<YOUR_ENV_RPC_VARIABLE_NAME>
 ```

## Running a Single Test Suite

To run specific test suites, use:

```bash
forge test --match-path "test/Soulbound.t.sol"
```

## Coverage

To generate coverage reports, first install genhtml:

```bash
brew install genhtml
```

> Note: If you encounter the error No available formula with the name "genhtml". Did you mean ekhtml?, run the following command:

```bash
brew install lcov
```

Finally, generate the coverage report with:

```bash
yarn run coverage
```
</details>

---


## Contracts

The Solidity smart contracts are located in the `src` directory.

```ml
├─ BasicERC721 — "Simple ERC721 contract"
├─ BasicERC1155 — "Simple ERC1155 contract"
├─ CrowdFunding — "Crowdfunding contract"
├─ FixedERC20 — "Fixed supply ERC20 contract"
├─ SoulboundNFT — "Single mint, non-transferable NFT contract"
upgradable/
├─ FreeMintERC721 — "Single free mint per address ERC721 contract"

```

## Directories

```ml
src — "Solidity smart contracts"
test — "Foundry Forge tests"
```

## Safety


I **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.

Please always include your own thorough tests when using Solstack to make sure it works correctly with your code.  

## Acknowledgements

This repository is inspired by or directly modified from many sources, primarily:

- [Solmate](https://github.com/transmissions11/solmate)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Solidity-By-Example](https://github.com/solidity-by-example/solidity-by-example.github.io)


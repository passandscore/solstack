# **Passandscore Contracts**

These contracts are variants of ERC standards, inspired by well-known libraries like OpenZeppelin. They are written in Solidity and tested using Foundry.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## **Installation and Development**

To start developing with the ERC20 abstract contract, follow these steps:

### **Install Foundry**

Foundry is a comprehensive toolchain for smart contract development. Install it using:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

## Quickstart Command

Run this command to install dependencies, compile contracts, and execute all tests:

```bash
make
```

## Running a Single Test Suite

To run specific test suites, use:

```bash
forge test --match-path "test/token/ERC20/*.t.sol"
forge test --match-path "test/token/ERC721/*.t.sol"
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

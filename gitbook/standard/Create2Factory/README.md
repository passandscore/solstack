# CREATE2 Contract Factory

A secure contract factory implementation using the CREATE2 opcode, enabling deterministic smart contract deployment across different networks.

## What is CREATE2?

CREATE2 is an Ethereum opcode that allows for deterministic contract deployment. Unlike the regular CREATE opcode which uses the deployer's nonce to determine the new contract's address, CREATE2 uses a custom "salt" value to compute the address. This means that:

1. The same contract can be deployed to the same address on different networks
2. The deployment address can be computed before the contract is actually deployed
3. Contracts can be deployed in a specific order, regardless of the deployer's nonce

## Why Use CREATE2?

The CREATE2 factory is particularly useful for:

- Cross-chain deployments where you need the same contract address on different networks
- Upgradeable contracts where you need to predict the address of the implementation contract
- Complex deployment scenarios where contract addresses need to be known in advance
- Gas-efficient deployments by reusing the same factory contract

## How to Use

### 1. Generate a Salt

To deploy a contract using CREATE2, you first need to generate a unique salt. 

### 2. Deploy the Factory

Before deploying any contracts, you need to deploy the CREATE2 factory to your target network.

### 3. Deploy Contracts

Once the factory is deployed, you can use it to deploy contracts deterministically. The factory provides two main functions:

- `safeCreate2`: Deploys a contract using CREATE2
- `findCreate2Address`: Computes the future deployment address for a given salt and contract bytecode

To deploy a contract:
1. Generate a salt
2. Use the factory's `safeCreate2` function with the generated salt and your contract's bytecode
3. The contract will be deployed to a deterministic address that can be computed using `findCreate2Address`

## Security Considerations

1. The factory is owned and only the owner can deploy contracts
2. Each address can only be deployed to once
3. The factory tracks all deployments to prevent redeployment
4. The salt generation process is deterministic and verifiable


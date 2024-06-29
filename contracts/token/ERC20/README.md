# **ERC20 Abstract Contract**

**ERC20** is an abstract contract that defines the standard interface for ERC20 tokens, compliant with the ERC-20 standard as outlined in [EIP-20](https://eips.ethereum.org/EIPS/eip-20).

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## **Overview**

The **ERC20** abstract contract provides a robust foundation for developing ERC-20 compliant tokens. It standardizes the core functionality of token creation, management, and transfer, ensuring compatibility and interoperability within the Ethereum ecosystem.

## **Features**

- **Total Supply:** Defines the total amount of tokens in existence.
- **Balance Tracking:** Keeps track of the balance of tokens held by each address.
- **Transfer Function:** Allows token transfers between addresses.
- **Allowance System:** Enables token holders to approve third parties to transfer tokens on their behalf.
- **Transfer Events:** Emits events for tracking transfers and approvals.
- **Decimals & Metadata:** Includes token metadata like name, symbol, and decimals.

## **Functionality**

### **1. Total Supply**

Returns the total supply of tokens.

```solidity
function totalSupply() public view returns (uint256);
```

### **2. Balance Of**

Returns the balance of a specific address.

```solidity
function balanceOf(address _owner) public view returns (uint256 balance);
```

### **3. Transfer**

Transfers tokens from the sender to a recipient.

```solidity
function transfer(address _to, uint256 _value) public returns (bool success);
```

### **4. Approve**

Approves a spender to transfer up to a specified amount on behalf of the token owner.

```solidity
function approve(address _spender, uint256 _value) public returns (bool success);
```

### **5. Allowance**

Returns the remaining number of tokens that the spender is allowed to spend on behalf of the token owner.

```solidity
function allowance(address _owner, address _spender) public view returns (uint256 remaining);
```

### **6. Transfer From**

Transfers tokens on behalf of the token owner to a recipient.

```solidity
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
```

## **Events**

### **Transfer**

Emitted when tokens are transferred.

```solidity
event Transfer(address indexed _from, address indexed _to, uint256 _value);
```

### **Approval**

Emitted when a token owner approves a spender.

```solidity
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
```

## **Installation and Development**

To get started with development using the ERC20 abstract contract, follow these steps:

## Install Foundry

- Foundry is a smart contract development toolchain.

```bash
curl -L https://foundry.paradigm.xyz | bash
```

### Quickstart Command

```bash
make
```

### Coverage

You will need to install

```bash
brew install genhtml
```

> No available formula with the name "genhtml". Did you mean ekhtml?

If you get this error, run the following command:

```bash
brew install genhtml
```

Finally, run the following command to generate coverage:

```bash
yarn run coverage
````

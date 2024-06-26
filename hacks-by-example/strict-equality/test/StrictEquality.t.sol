// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {VulnerableContract, Attack} from "../src/StrictEquality.sol";

contract VulnerableContractTest is Test {
    VulnerableContract private vulnerableContract;
    Attack private attackContract;

    function setUp() public {
        vulnerableContract = new VulnerableContract();
        attackContract = new Attack(address(vulnerableContract));
    }

    
    function testAttack() public {
        // Deposit 1 Ether to the VulnerableContract
        uint256 initialDeposit = 1 ether;
        vm.deal(address(this), initialDeposit);
        vulnerableContract.deposit{value: initialDeposit}();

        // Check initial balances
        assertEq(vulnerableContract.getBalance(), initialDeposit);
        assertEq(vulnerableContract.getTotalDeposited(), initialDeposit);

        // Fund the Attack contract
        uint256 attackFunds = 1 ether;
        vm.deal(address(attackContract), attackFunds);
        
        // Verify that the Attack contract has the correct balance
        assertEq(address(attackContract).balance, attackFunds);

        // Perform attack by self-destructing the Attack contract and sending Ether directly to VulnerableContract
        attackContract.attack();

        // VulnerableContract now has 2 Ether, but totalDeposited is still 1 Ether
        assertEq(vulnerableContract.getBalance(), initialDeposit + attackFunds);
        assertEq(vulnerableContract.getTotalDeposited(), initialDeposit);

        // Attempt to withdraw all funds (should fail)
        vm.expectRevert();
        vulnerableContract.withdrawAll();
    }
}

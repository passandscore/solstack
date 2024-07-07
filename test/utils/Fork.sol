// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "@forge-std-1.8.2/Test.sol";

abstract contract Fork is Test {
    // the identifiers of the forks
    uint256 public mainnetFork;

    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need

    //inside your .env file e.g:
    //RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    //string RPC_URL_key = vm.envString("RPC_URL");

    // Enabling a specific fork is done via passing that forkId to selectFork.
    // vm.selectFork(mainnetFork);

    // Similar to roll, you can set block.number of a fork with rollFork.
    // vm.rollFork(1_337_000);

    // create two _different_ forks during setup
    function runFork() public virtual {

        // Mainnet fork
        string memory RPC_URL_key = "RPC_URL";
        string memory RPC_URL = vm.envString(RPC_URL_key);
        mainnetFork = vm.createFork(RPC_URL);

    }
}

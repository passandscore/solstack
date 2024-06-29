// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import "forge-std/Test.sol";

abstract contract Fork is Test {
    // the identifiers of the forks
    uint256 public mainnetFork;

    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need

    //inside your .env file e.g:
    //MAINNET_RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    //string mainnet_rpc_url_key = vm.envString("MAINNET_RPC_URL");

    // Enabling a specific fork is done via passing that forkId to selectFork.
    // vm.selectFork(mainnetFork);

    // Similar to roll, you can set block.number of a fork with rollFork.
    // vm.rollFork(1_337_000);

    // create fork during setup
    function setUp() public virtual {
        // Mainnet fork
        string memory mainnet_rpc_url_key = "MAINNET_RPC_URL";
        string memory mainnet_rpc_url = vm.envString(mainnet_rpc_url_key);
        mainnetFork = vm.createFork(mainnet_rpc_url);
    }
}

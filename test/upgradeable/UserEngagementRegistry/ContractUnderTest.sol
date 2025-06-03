// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;


import {UserEngagementRegistry} from "../../../src/upgradeable/UserEngagementRegistry.sol";
import {Fork} from "../../utils/Fork.sol";

abstract contract ContractUnderTest is Fork {

    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));
    address payable unauthorizedUser = payable(makeAddr("unauthorizedUser"));
    

    UserEngagementRegistry internal userEngagementRegistry;


    function setUp() public virtual {
        runFork();
        vm.selectFork(mainnetFork);

        vm.startPrank({msgSender: deployer});

        userEngagementRegistry = new UserEngagementRegistry();
        userEngagementRegistry.initialize();


        vm.label({
            account: address(userEngagementRegistry),
            newLabel: "UserEngagementRegistry"
        });


       
    }
}

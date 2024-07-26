// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {RaffleRegistry} from "../src/RaffleRegistry.sol";
import {Fork} from "./utils/Fork.sol";

abstract contract Base is Fork {
    RaffleRegistry contractUnderTest;
    string uri = "https://api.RaffleRegistry.com/";

    address payable deployer = payable(makeAddr("deployer"));
    address payable minter = payable(makeAddr("minter"));
    address payable unauthorized = payable(makeAddr("unauthorized"));

    function deploy() public {
        // setup mainnet fork
        runFork();
        vm.selectFork(mainnetFork);

        vm.startPrank(deployer);
        contractUnderTest = new RaffleRegistry();

        // label the contracts
        vm.label(address(contractUnderTest), "contractUnderTest");

        // label the EOAs
        vm.label(deployer, "deployer");
        vm.label(minter, "minter");
        vm.label(unauthorized, "unauthorized");

        vm.stopPrank();
    }
}

contract Deployment is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_set_owner() public view {
        assertEq(deployer, contractUnderTest.owner());
    }
}

contract RegisterRaffle is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_revert_when_registering_raffle_with_unauthorized()
        public
    {
        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");

        string memory name = "raffle1";
        string memory uri = "uri1/";

        contractUnderTest.registerRaffle(name, uri);
    }

    function test_should_register_raffle() public {
        vm.startPrank(deployer);
        string memory name = "raffle1";
        string memory uri = "uri1/";

        contractUnderTest.registerRaffle(name, uri);
        RaffleRegistry.Raffle memory raffle = contractUnderTest
            .getRaffleDetails(1);

        assertEq(name, raffle.name);
        assertEq(uri, raffle.uri);
        assertEq(1, raffle.id);
    }

    function test_should_emit_event_when_registering_raffle() public {
        vm.startPrank(deployer);
        string memory name = "raffle1";
        string memory uri = "uri1/";

        vm.expectEmit();
        emit RaffleRegistry.RegisterRaffle(1, name, "uri1/1.json");

        contractUnderTest.registerRaffle(name, uri);
    }
}

contract UpdateRaffle is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_update_raffle() public {
        vm.startPrank(deployer);
        string memory name = "raffle1";
        string memory uri = "uri1/";

        contractUnderTest.registerRaffle(name, uri);
        RaffleRegistry.Raffle memory raffle = contractUnderTest
            .getRaffleDetails(1);

        assertEq(name, raffle.name);
        assertEq(uri, raffle.uri);
        assertEq(1, raffle.id);

        string memory name2 = "raffle2";
        string memory uri2 = "uri2/";
        contractUnderTest.updateRaffle(1, name2, uri2);

        RaffleRegistry.Raffle memory raffleAfter = contractUnderTest
            .getRaffleDetails(1);

        assertEq(name2, raffleAfter.name);
        assertEq(uri2, raffleAfter.uri);
        assertEq(1, raffleAfter.id);
    }

    function test_should_revert_when_updating_raffle_with_unauthorized()
        public
    {
        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");

        string memory name2 = "raffle2";
        string memory uri2 = "uri2/";
        contractUnderTest.updateRaffle(1, name2, uri2);
    }

    function test_should_emit_event_when_updating_raffle() public {
        vm.startPrank(deployer);
        string memory name = "raffle1";
        string memory uri = "uri1/";

        contractUnderTest.registerRaffle(name, uri);
        RaffleRegistry.Raffle memory raffle = contractUnderTest
            .getRaffleDetails(1);

        assertEq(name, raffle.name);
        assertEq(uri, raffle.uri);
        assertEq(1, raffle.id);

        string memory name2 = "raffle2";
        string memory uri2 = "uri2/";

        vm.expectEmit();
        emit RaffleRegistry.UpdateRaffle(1, name2, "uri2/");

        contractUnderTest.updateRaffle(1, name2, uri2);
    }

    function test_should_revert_when_raffle_does_not_exist() public {
        vm.startPrank(deployer);
        vm.expectRevert(RaffleRegistry.RaffleDoesNotExist.selector);

        string memory name = "raffle1";
        string memory uri = "uri1/";

        contractUnderTest.updateRaffle(1, name, uri);
    }

    function test_should_revert_when_uri_string_is_empty() public {
        vm.startPrank(deployer);

        string memory name = "raffle1";
        string memory uri = "uri1/";

        contractUnderTest.registerRaffle(name, uri);

        vm.expectRevert(RaffleRegistry.InvalidInput.selector);
        contractUnderTest.updateRaffle(1, name, "");
    }

    function test_should_revert_when_raffle_name_is_empty() public {
        vm.startPrank(deployer);

        string memory name = "raffle1";
        string memory uri = "uri1/";

        contractUnderTest.registerRaffle(name, uri);

        vm.expectRevert(RaffleRegistry.InvalidInput.selector);
        contractUnderTest.updateRaffle(1, "", uri);
    }
}

contract Uri is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_return_uri() public {
        vm.startPrank(deployer);
        string memory name = "raffle1";
        string memory uri = "uri1/";

        contractUnderTest.registerRaffle(name, uri);
        assertEq(uri, contractUnderTest.uri(1));
    }
}

contract setRaffleWinners is Base {
    function setUp() public {
        super.deploy();
    }


    function test_should_batch_mint() public {
        vm.startPrank(deployer);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 100;
        amounts[1] = 200;
        contractUnderTest.setRaffleWinners(minter, ids, amounts, "");
        assertEq(100, contractUnderTest.balanceOf(minter, 1));
        assertEq(200, contractUnderTest.balanceOf(minter, 2));
    }

    function test_should_not_batch_mint() public {
        vm.startPrank(unauthorized);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 100;
        amounts[1] = 200;

        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.setRaffleWinners(unauthorized, ids, amounts, "");
    }
}

contract removeRaffleWinners is Base {
    function setUp() public {
        super.deploy();
    }


    function test_should_batch_burn() public {
        vm.startPrank(deployer);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 100;
        amounts[1] = 200;
        contractUnderTest.setRaffleWinners(minter, ids, amounts, "");
        contractUnderTest.removeRaffleWinners(minter, ids, amounts);
        assertEq(0, contractUnderTest.balanceOf(minter, 1));
        assertEq(0, contractUnderTest.balanceOf(minter, 2));
    }

    function test_should_not_batch_burn() public {
        vm.startPrank(deployer);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 100;
        amounts[1] = 200;
        contractUnderTest.setRaffleWinners(minter, ids, amounts, "");
        vm.stopPrank();

        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.removeRaffleWinners(unauthorized, ids, amounts);
    }
}

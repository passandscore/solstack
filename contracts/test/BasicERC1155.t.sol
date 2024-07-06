// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BasicERC1155} from "../src/BasicERC1155.sol";

import {Test} from "@forge-std/Test.sol";
import {Fork} from "./utils/Fork.sol";

abstract contract Base is Test, Fork {
    BasicERC1155 contractUnderTest;
    string uri = "https://api.BasicERC1155.com/";


    address payable deployer = payable(makeAddr("deployer"));
    address payable minter = payable(makeAddr("minter"));
    address payable unauthorized = payable(makeAddr("unauthorized"));

    function deploy() public {
        // setup mainnet fork
        runFork();
        vm.selectFork(mainnetFork);

        vm.startPrank(deployer);
        contractUnderTest = new BasicERC1155(
            uri
        );

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

    function test_should_set_uri() public view {
        assertEq("https://api.BasicERC1155.com/", contractUnderTest.uri(1));
    }
}

contract Minting is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_mint() public {
        vm.startPrank(deployer);
        contractUnderTest.mint(minter, 1, 100, "");
        assertEq(100, contractUnderTest.balanceOf(minter, 1));
    }

    function test_should_not_mint() public {
        vm.startPrank(unauthorized);

        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.mint(unauthorized, 1, 100, "");
    }

    function test_should_batch_mint() public {
        vm.startPrank(deployer);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 100;
        amounts[1] = 200;
        contractUnderTest.mintBatch(minter, ids, amounts, "");
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
        contractUnderTest.mintBatch(unauthorized, ids, amounts, "");
    }
}

contract Burning is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_burn() public {
        vm.startPrank(deployer);
        contractUnderTest.mint(minter, 1, 100, "");
        contractUnderTest.burn(minter, 1, 100);
        assertEq(0, contractUnderTest.balanceOf(minter, 1));
    }

    function test_should_not_burn() public {
        vm.startPrank(deployer);
        contractUnderTest.mint(minter, 1, 100, "");
        vm.stopPrank();

        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.burn(unauthorized, 1, 100);
    }

    function test_should_batch_burn() public {
        vm.startPrank(deployer);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 100;
        amounts[1] = 200;
        contractUnderTest.mintBatch(minter, ids, amounts, "");
        contractUnderTest.burnBatch(minter, ids, amounts);
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
        contractUnderTest.mintBatch(minter, ids, amounts, "");
        vm.stopPrank();

        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.burnBatch(unauthorized, ids, amounts);
    }
}


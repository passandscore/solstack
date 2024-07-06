// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BasicERC721} from "../src/BasicERC721.sol";

import {Test} from "@forge-std/Test.sol";
import {Fork} from "./utils/Fork.sol";

abstract contract Base is Test, Fork {
    BasicERC721 contractUnderTest;
    string uri = "https://api.BasicERC721.com/";

    address payable deployer = payable(makeAddr("deployer"));
    address payable minter = payable(makeAddr("minter"));
    address payable unauthorized = payable(makeAddr("unauthorized"));

    function deploy() public {
        runFork();
        vm.selectFork(mainnetFork);

        string memory name = "BasicERC721";
        string memory symbol = "BASIC";
        uint256 price = 1 ether;
        uint256 maxSupply = 10000;

        vm.startPrank(deployer);
        contractUnderTest = new BasicERC721(
            name,
            symbol,
            uri,
            price,
            maxSupply
        );

        // label the contracts
        vm.label(address(contractUnderTest), "contractUnderTest");

        // label the EOAs
        vm.label(deployer, "deployer");
        vm.label(minter, "minter");
        vm.label(unauthorized, "unauthorized");

        // fund the eoas
        vm.deal(deployer, 100 ether);
        vm.deal(minter, 100 ether);
        vm.deal(unauthorized, 100 ether);


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

    function test_should_set_symbol() public view {
        assertEq("BASIC", contractUnderTest.symbol());
    }

    function test_should_set_base_uri() public view {
        assertEq(uri, contractUnderTest.baseURI());
    }

    function test_should_set_mint_price() public view {
        assertEq(1 ether, contractUnderTest.mintPrice());
    }

    function test_should_set_max_supply() public view {
        assertEq(10000, contractUnderTest.MAX_SUPPLY());
    }

    function test_should_support_ERC721() public view {
        assert(contractUnderTest.supportsInterface(0x80ac58cd));
    }
}

contract Minting is Base {
    function setUp() public {
        super.deploy();
    }
    function test_should_mint() public {
        vm.startPrank(minter);
        contractUnderTest.mint{value: 1 ether}(1);
        vm.stopPrank();

        assertEq(1, contractUnderTest.totalSupply());
        assertEq(minter, contractUnderTest.ownerOf(1));
        assertEq(1, contractUnderTest.balanceOf(minter));
    }

    function test_should_mint_multiple() public {
        vm.startPrank(minter);
         contractUnderTest.mint{value: 10 ether}(10);
        assertEq(10, contractUnderTest.totalSupply());
        assertEq(10, contractUnderTest.balanceOf(minter));

        for (uint256 i = 1; i <= 10; i++) {
            assertEq(minter, contractUnderTest.ownerOf(i));
        }
    }

    function test_should_return_token_uri() public {
        vm.startPrank(minter);
        contractUnderTest.mint{value: 1 ether}(1);
        vm.stopPrank();

        string memory expectedURI = string(abi.encodePacked(uri, "1"));
        assertEq(expectedURI, contractUnderTest.tokenURI(1));
    }

    function test_should_revert_when_sale_is_not_active() public {
        vm.startPrank(deployer);
        contractUnderTest.pauseMint();
        vm.stopPrank();

        vm.startPrank(minter);
        bytes4 selector = BasicERC721.SaleNotActive.selector;
        vm.expectRevert(abi.encodeWithSelector(selector));
        contractUnderTest.mint(1);
    }

    function test_should_revert_when_exceeds_max_supply() public {
        vm.startPrank(minter);
        bytes4 selector = BasicERC721.ExceedsMaxSupply.selector;
        vm.expectRevert(abi.encodeWithSelector(selector));
        contractUnderTest.mint(10001);
    }

    function test_should_revert_when_insufficient_value() public {
        vm.startPrank(minter);
        vm.deal(minter, 1);

        bytes4 selector = BasicERC721.InsufficientValue.selector;
        vm.expectRevert(abi.encodeWithSelector(selector));
        contractUnderTest.mint(2);
    }

    function test_should_adminMint_when_owner() public {
        vm.startPrank(deployer);
        contractUnderTest.adminMint(1);

        assertEq(1, contractUnderTest.totalSupply());
        assertEq(deployer, contractUnderTest.ownerOf(1));
        assertEq(1, contractUnderTest.balanceOf(deployer));
    }

    function test_should_mint_multiple_when_owner() public {
        vm.startPrank(deployer);
        contractUnderTest.adminMint(10);

        assertEq(10, contractUnderTest.totalSupply());
        assertEq(10, contractUnderTest.balanceOf(deployer));

        for (uint256 i = 1; i <= 10; i++) {
            assertEq(deployer, contractUnderTest.ownerOf(i));
        }
    }

    function test_should_revert_adminMint_when_not_owner() public {
        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.adminMint(1);
    }

    function test_should_revert_when_exceeds_max_supply_adminMint() public {
        vm.startPrank(deployer);
        bytes4 selector = BasicERC721.ExceedsMaxSupply.selector;
        vm.expectRevert(abi.encodeWithSelector(selector));
        contractUnderTest.adminMint(10001);
    }
}

contract OwnerMethods is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_withdraw() public {
        vm.startPrank(minter);
        contractUnderTest.mint{value: 10 ether}(10);
        vm.stopPrank();

        vm.startPrank(deployer);
        contractUnderTest.withdraw();

        assertEq(0, address(contractUnderTest).balance);
        }

    function test_should_revert_withdraw_when_not_owner() public {
        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.withdraw();
    }

    function test_should_pauseMint() public {
        vm.startPrank(deployer);
        contractUnderTest.pauseMint();
        vm.stopPrank();

        assert(contractUnderTest.isMintOpen() == false);
    }

    function test_should_revert_pauseMint_when_not_owner() public {
        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.pauseMint();
    }

    function test_should_resumeMint() public {
        vm.startPrank(deployer);
        contractUnderTest.pauseMint();
        assert(contractUnderTest.isMintOpen() == false);

        contractUnderTest.resumeMint();

        assert(contractUnderTest.isMintOpen() == true);
    }

    function test_should_revert_resumeMint_when_not_owner() public {
         vm.startPrank(deployer);
        contractUnderTest.pauseMint();
        assert(contractUnderTest.isMintOpen() == false);
        vm.stopPrank();

        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.resumeMint();
    }

    function test_should_set_mint_price() public {
        vm.startPrank(deployer);
        contractUnderTest.setMintPrice(2 ether);
        vm.stopPrank();

        assertEq(2 ether, contractUnderTest.mintPrice());
    }

    function test_should_revert_set_mint_price_when_not_owner() public {
        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.setMintPrice(2 ether);
    }

    function test_should_set_base_uri() public {
        string memory newURI = "https://api.NewBasicERC721.com/";
        assertNotEq(newURI, contractUnderTest.baseURI());


        vm.startPrank(deployer);
        contractUnderTest.setBaseURI(newURI);
        vm.stopPrank();

        assertEq(newURI, contractUnderTest.baseURI());
    }

    function test_should_revert_set_base_uri_when_not_owner() public {
        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.setBaseURI("not allowed");
    }
}

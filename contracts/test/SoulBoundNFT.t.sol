// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {SoulboundNFT} from "../src/SoulboundNFT.sol";
import {Fork} from "./utils/Fork.sol";

abstract contract Base is Fork {
    SoulboundNFT contractUnderTest;
    string baseURI = "https://api.soulboundnft.com/";


    address payable deployer = payable(makeAddr("deployer"));
    address payable minter = payable(makeAddr("minter"));
    address payable unauthorized = payable(makeAddr("unauthorized"));

    function deploy() public {
        // setup mainnet fork
        runFork();
        vm.selectFork(mainnetFork);

        vm.startPrank(deployer);

        string memory name = "SoulboundNFT";
        string memory symbol = "SBNFT";
        uint256 maxSupply = 10000;
        uint8 maxMintPerWallet = 1;

        contractUnderTest = new SoulboundNFT(
            name,
            symbol,
            baseURI,
            maxSupply,
            maxMintPerWallet
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

    function test_should_set_base_uri() public view {
        assertEq("https://api.soulboundnft.com/", contractUnderTest.baseURI());
    }

    function test_should_set_name() public view {
        assertEq("SoulboundNFT", contractUnderTest.name());
    }

    function test_should_set_symbol() public view {
        assertEq("SBNFT", contractUnderTest.symbol());
    }

    function test_should_set_max_supply() public view {
        assertEq(10000, contractUnderTest.MAX_SUPPLY());
    }

    function test_should_set_max_mint_per_wallet() public view {
        assertEq(1, contractUnderTest.maxMintPerWallet());
    }
}

contract Minting is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_increase_total_supply() public {
        vm.startPrank(minter);
        contractUnderTest.mint(1);
        assertEq(1, contractUnderTest.totalSupply());
    }

    function test_should_increase_balanceOf_when_minting() public {

        vm.startPrank(deployer);
        contractUnderTest.setMaxMintPerWallet(0);
        vm.stopPrank();

        vm.startPrank(minter);
        contractUnderTest.mint(1);
        assertEq(1, contractUnderTest.balanceOf(minter));


        contractUnderTest.mint(10);
        assertEq(11, contractUnderTest.balanceOf(minter));

        for (uint256 i = 1; i <= 11; i++) {
            assertEq(minter, contractUnderTest.ownerOf(i));
        }
    }

     function test_should_set_ownerOf_when_minting() public {

        vm.startPrank(deployer);
        contractUnderTest.setMaxMintPerWallet(0);
        vm.stopPrank();

        vm.startPrank(minter);
        contractUnderTest.mint(10);

        for (uint256 i = 1; i <= 10; i++) {
            assertEq(minter, contractUnderTest.ownerOf(i));
        }
    }

    function test_should_revert_when_max_supply_reached() public {
        vm.startPrank(deployer);
        contractUnderTest.setMaxMintPerWallet(0);
        vm.stopPrank();

        vm.startPrank(minter);
        uint256 maxSupply = contractUnderTest.MAX_SUPPLY();
            contractUnderTest.mint(maxSupply);
            assertEq(maxSupply, contractUnderTest.totalSupply());
            
            bytes4 selector = SoulboundNFT.MaxSupplyReached.selector;
            vm.expectRevert(abi.encodeWithSelector(selector));

            contractUnderTest.mint( 1);
    }

    function test_should_revert_when_max_mint_per_wallet_reached() public {
        vm.startPrank(minter);
        contractUnderTest.mint(1);

        bytes4 selector = SoulboundNFT.ExceedsMaxMintPerWallet.selector;
        vm.expectRevert(abi.encodeWithSelector(selector));

        contractUnderTest.mint( 1);

    }
    }

    contract Metadata is Base {
    function setUp() public {
        super.deploy();
    }  
    function test_should_revert_when_unauthorized_calling_setBaseURI() public {
        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");

        contractUnderTest.setBaseURI("api.soulboundnft.com/");
    }

    function test_should_set_base_uri() public {
        string memory newURI = "api.newuri.com/";

        vm.startPrank(deployer);
        contractUnderTest.setBaseURI(newURI);
        assertEq(newURI, contractUnderTest.baseURI());
    }

    function test_should_return_base_uri() public view {
        assertEq(baseURI, contractUnderTest.tokenURI(1));
    }

    function test_should_return_base_uri_when_calling_tokenURI() public view {
        assertEq(baseURI, contractUnderTest.tokenURI(1));
    } 
    }

contract Transfer is Base {
    function setUp() public {
        super.deploy();
    }    

    function test_should_revert_when_calling_transferFrom() public {
        vm.startPrank(minter);
        contractUnderTest.mint( 1);
        vm.stopPrank();

        bytes4 selector = SoulboundNFT.SoulBoundToken_TransferNotAllowed.selector;
        vm.expectRevert(abi.encodeWithSelector(selector));

        contractUnderTest.transferFrom(minter, unauthorized, 1);
    }

    function test_should_revert_when_calling_safeTransferFrom() public {
        vm.startPrank(minter);
        contractUnderTest.mint( 1);
        vm.stopPrank();

        bytes4 selector = SoulboundNFT.SoulBoundToken_TransferNotAllowed.selector;
        vm.expectRevert(abi.encodeWithSelector(selector));

        contractUnderTest.safeTransferFrom(minter, unauthorized, 1);
    }

    function test_should_revert_when_calling_safeTransferFrom_with_data() public {
        vm.startPrank(minter);
        contractUnderTest.mint( 1);
        vm.stopPrank();

        bytes4 selector = SoulboundNFT.SoulBoundToken_TransferNotAllowed.selector;
        vm.expectRevert(abi.encodeWithSelector(selector));

        contractUnderTest.safeTransferFrom(minter, unauthorized, 1, "0x");
    }
}


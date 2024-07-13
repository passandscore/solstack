// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {RentableNFT} from "../src/RentableNFT.sol";
import {Fork} from "./utils/Fork.sol";
import {console} from "@forge-std-1.8.2/Console.sol";
import {IERC4907} from "../src/interfaces/IERC4907.sol";
import {ERC721} from "@solmate-6.7.0/tokens/ERC721.sol";

abstract contract Base is Fork {
    RentableNFT contractUnderTest;
    string name = "RentableNFT";
    string symbol = "RNT";
    string uri = "https://api.com/nft/";
    uint256 price = 1 ether;
    uint256 maxSupply = 100;
    uint256 rentalPricePerDay = .1 ether;
    uint256 maxDaysPerRental = 10;

    address payable deployer = payable(makeAddr("deployer"));
    address payable renter1 = payable(makeAddr("renter1"));
    address payable renter2 = payable(makeAddr("renter2"));
    address payable unauthorized = payable(makeAddr("unauthorized"));

    function deploy() public {
        runFork();
        vm.selectFork(mainnetFork);

        // fund the EOAs
        vm.deal(deployer, 1000 ether);
        vm.deal(renter1, 100 ether);
        vm.deal(renter2, 100 ether);
        vm.deal(unauthorized, 100 ether);

        vm.startPrank(deployer);

        contractUnderTest = new RentableNFT(
            name,
            symbol,
            uri,
            price,
            maxSupply,
            rentalPricePerDay,
            maxDaysPerRental
        );

        // label the contracts
        vm.label(address(contractUnderTest), "contractUnderTest");

        // label the EOAs
        vm.label(deployer, "deployer");
        vm.label(renter1, "renter1");
        vm.label(renter2, "renter2");
        vm.label(unauthorized, "unauthorized");

        // mint the max supply to the deployer
        contractUnderTest.mint{value: price * maxSupply}(maxSupply);

        vm.stopPrank();
    }
}

contract Deployment is Base {
    function setUp() public {
        deploy();
    }

    function test_should_set_name() public view {
        assertEq(contractUnderTest.name(), name);
    }

    function test_should_set_symbol() public view {
        assertEq(contractUnderTest.symbol(), symbol);
    }

    function test_should_set_uri() public view {
        assertEq(contractUnderTest.baseURI(), uri);
    }

    function test_should_set_price() public view {
        assertEq(contractUnderTest.mintPrice(), price);
    }

    function test_should_set_max_supply() public view {
        assertEq(contractUnderTest.MAX_SUPPLY(), maxSupply);
    }

    function test_should_set_rental_price_per_day() public view {
        assertEq(contractUnderTest.rentalPricePerDay(), rentalPricePerDay);
    }

    function test_should_set_max_days_per_rental() public view {
        assertEq(contractUnderTest.maxDaysPerRental(), maxDaysPerRental);
    }
}

contract SetUser is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_token_not_found() public {
        uint256 invalidTokenId = 101;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(deployer);
        vm.expectRevert("NOT_MINTED");
        contractUnderTest.setUser(invalidTokenId, renter1, expires);
    }

    function test_should_revert_when_token_is_rented() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(deployer);
        contractUnderTest.setUser(tokenId, renter1, expires);

        vm.expectRevert(RentableNFT.AlreadyRented.selector);
        contractUnderTest.setUser(tokenId, renter1, expires);
    }

    function test_should_revert_when_user_is_invalid() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(deployer);
        vm.expectRevert(RentableNFT.InvalidUser.selector);
        contractUnderTest.setUser(tokenId, address(0), expires);
    }

    function test_should_revert_when_invalid_expiration() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(0);

        vm.startPrank(deployer);
        vm.expectRevert(RentableNFT.InvalidExpiration.selector);
        contractUnderTest.setUser(tokenId, renter1, expires);
    }

    function test_should_revert_when_renting_for_more_than_max_days() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(
            block.timestamp + (maxDaysPerRental * 1 days) + 1 days
        );

        vm.startPrank(deployer);
        vm.expectRevert(RentableNFT.ExceedsMaxRentalDays.selector);
        contractUnderTest.setUser(tokenId, renter1, expires);
    }

    function test_should_revert_when_caller_is_not_owner_or_approved() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(unauthorized);
        vm.expectRevert(RentableNFT.NotApprovedOrOwner.selector);
        contractUnderTest.setUser(tokenId, renter1, expires);
    }

    function test_should_update_rental_info() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(deployer);
        contractUnderTest.setUser(tokenId, renter1, expires);

        (uint256 _price, address _user, uint64 _expires) = contractUnderTest
            .getRentalInfo(tokenId);
        assertEq(_price, 0);
        assertEq(_user, renter1);
        assertEq(_expires, expires);
    }

    function test_should_emit_update_user_event() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.expectEmit();
        emit IERC4907.UpdateUser(tokenId, renter1, expires);

        vm.startPrank(deployer);
        contractUnderTest.setUser(tokenId, renter1, expires);
    }
}

contract Rent is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_rental_not_available() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(deployer);
        contractUnderTest.setUser(tokenId, renter1, expires);

        vm.expectRevert(RentableNFT.AlreadyRented.selector);
        contractUnderTest.rent(tokenId, expires);
    }

    function test_should_revert_when_user_is_invalid() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(address(0));
        vm.expectRevert(RentableNFT.InvalidUser.selector);
        contractUnderTest.rent(tokenId, expires);
    }

    function test_should_revert_when_invalid_expiration() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(0);

        vm.startPrank(renter1);
        vm.expectRevert(RentableNFT.InvalidExpiration.selector);
        contractUnderTest.rent(tokenId, expires);
    }

    function test_should_revert_when_token_is_permissoned() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(deployer);
        contractUnderTest.setPermissionedRental(tokenId, true);
        vm.stopPrank();

        bytes4 selector = RentableNFT.PermissionedRental.selector;

        vm.expectRevert(abi.encodeWithSelector(selector, tokenId));

        vm.startPrank(renter1);
        contractUnderTest.rent(tokenId, expires);
    }


    function test_should_revert_when_renting_for_more_than_max_days() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(
            block.timestamp + (maxDaysPerRental * 1 days) + 1 days
        );

        vm.startPrank(renter1);
        vm.expectRevert(RentableNFT.ExceedsMaxRentalDays.selector);
        contractUnderTest.rent(tokenId, expires);
    }

    function test_should_revert_when_insufficient_funds() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.deal(renter1, 0 ether);

        vm.startPrank(renter1);
        vm.expectRevert(RentableNFT.InsufficientFunds.selector);
        contractUnderTest.rent(tokenId, expires);
    }

    function test_should_update_rental_info() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        (uint256 totalDaysRented, ) = contractUnderTest.getRentalEstimate(
            expires
        );

        vm.startPrank(renter1);
        contractUnderTest.rent{value: rentalPricePerDay * totalDaysRented}(
            tokenId,
            expires
        );

        (uint256 _price, address _user, uint64 _expires) = contractUnderTest
            .getRentalInfo(tokenId);

        assertEq(_price, rentalPricePerDay * totalDaysRented);
        assertEq(_user, renter1);
        assertEq(_expires, expires);
    }

    function test_should_emit_update_user_event() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        (uint256 totalDaysRented, ) = contractUnderTest.getRentalEstimate(
            expires
        );

        vm.expectEmit();
        emit IERC4907.UpdateUser(tokenId, renter1, expires);

        vm.startPrank(renter1);
        contractUnderTest.rent{value: rentalPricePerDay * totalDaysRented}(
            tokenId,
            expires
        );
    }
}

contract UserOf is Base {
    function setUp() public {
        deploy();
    }

    function test_should_return_zero_address_when_token_is_not_rented() public view{
        uint256 tokenId = 1;
        assertEq(contractUnderTest.userOf(tokenId), address(0));
    }

    function test_should_return_user_address_when_token_is_rented() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(deployer);
        contractUnderTest.setUser(tokenId, renter1, expires);
        assertEq(contractUnderTest.userOf(tokenId), renter1);
    }
}

contract setPermissionedRental is Base {
    function setUp() public {
        deploy();
    
    }

    function test_should_revert_when_caller_is_not_token_owner() public {
        uint256 tokenId = 1;
        bool permissioned = true;

        vm.startPrank(unauthorized);
        vm.expectRevert(RentableNFT.NotApprovedOrOwner.selector);
        contractUnderTest.setPermissionedRental(tokenId, permissioned);
    }

    function test_should_update_permissioned_rental() public {
        uint256 tokenId = 1;

        assertEq(contractUnderTest.getPermissionedRental(tokenId), false);

        vm.startPrank(deployer);
        contractUnderTest.setPermissionedRental(tokenId, true);

        assertEq(contractUnderTest.getPermissionedRental(tokenId), true);
    }

    

}
      

contract SetRentalPricePerDay is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_caller_is_not_owner() public {
        vm.startPrank(unauthorized);
        vm.expectRevert("UNAUTHORIZED");
        contractUnderTest.setRentalPricePerDay(1 ether);
    }

    function test_should_update_rental_price_per_day() public {
        uint256 newRentalPricePerDay = 2 ether;

        vm.startPrank(deployer);
        contractUnderTest.setRentalPricePerDay(newRentalPricePerDay);
        assertEq(contractUnderTest.rentalPricePerDay(), newRentalPricePerDay);
    }

}

contract Burn is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_token_is_currently_rented() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1 days);

        vm.startPrank(deployer);
        contractUnderTest.setUser(tokenId, renter1, expires);

        vm.expectRevert(RentableNFT.AlreadyRented.selector);
        contractUnderTest.burn(tokenId);
    }

    function test_should_delete_renter_when_token_is_burned() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1 days);

        vm.startPrank(deployer);
        contractUnderTest.setUser(tokenId, renter1, expires);

        vm.warp(block.timestamp + 2 days);

        contractUnderTest.burn(tokenId);

        (uint256 _price, address _user, uint64 _expires) = contractUnderTest
            .getRentalInfo(tokenId);

        assertEq(_price, 0);
        assertEq(_user, address(0));
        assertEq(_expires, 0);
    }
    
}

contract ViewMethods is Base {
    function setUp() public {
        deploy();
    }

    function test_should_return_user_expires_timestamp() public {
        uint256 tokenId = 1;
        uint64 expires = uint64(block.timestamp + 1000);

        vm.startPrank(deployer);
        contractUnderTest.setUser(tokenId, renter1, expires);
        assertEq(contractUnderTest.userExpires(tokenId), expires);
    }

    function test_should_return_zero_when_token_has_not_been_initially_rented() public view{
        uint256 tokenId = 1;
        assertEq(contractUnderTest.userExpires(tokenId), 0);
    }
}

contract SupportsInterface is Base {
    function setUp() public {
        deploy();
    }

    function test_should_return_true_when_supports_IERC4907_interface() public view {
        assertTrue(contractUnderTest.supportsInterface(type(IERC4907).interfaceId));
    }

    function test_should_return_true_when_supports_ERC165_interface() public view {
        assertTrue(contractUnderTest.supportsInterface(0x01ffc9a7));
    }

     function test_should_return_true_when_supports_ERC721_interface() public view {
        assertTrue(contractUnderTest.supportsInterface(0x80ac58cd));
    }

     function test_should_return_true_when_supports_ERC721Metadata_interface() public view {
        assertTrue(contractUnderTest.supportsInterface(0x5b5e139f));
    }

    function test_should_return_false_when_does_not_support_unknown_interface() public view {
        assertFalse(contractUnderTest.supportsInterface(0x12345678));
    }
}



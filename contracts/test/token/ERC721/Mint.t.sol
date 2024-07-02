// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {IERC721Errors} from "src/interfaces/IERC6093.sol";

contract ERC721_Mint is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_if_to_is_zero_address() public {
        address to = address(0);
        uint256 tokenId = 1;

        bytes4 selector = IERC721Errors.ERC721InvalidReceiver.selector;

        vm.expectRevert(abi.encodeWithSelector(selector, to));
        contractUnderTest.mint(to, tokenId);
    }

    function test_should_increase_user_balance() public {
        address to = user1;
        uint256 tokenId = 1;

        contractUnderTest.mint(to, tokenId);
        assertEq(contractUnderTest.balanceOf(to), 1);
    }

    function test_should_set_owner_of_token() public {
        address to = user1;
        uint256 tokenId = 1;

        contractUnderTest.mint(to, tokenId);
        assertEq(contractUnderTest.ownerOf(tokenId), to);
    }
}

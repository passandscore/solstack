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
        bytes4 selector = IERC721Errors.ERC721InvalidOwner.selector;

        vm.expectRevert(abi.encodeWithSelector(selector, to));
        contractUnderTest.balanceOf(to);
    }


}

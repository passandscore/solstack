// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {IERC721Errors} from "src/interfaces/IERC6093.sol";
import {IERC165} from "src/interfaces/IERC165.sol";

contract ERC721_SupportsInterface is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_pass_if_supports_ERC165() public view {
        bytes4 interfaceId = type(IERC165).interfaceId;
        assert(contractUnderTest.supportsInterface(interfaceId));
    }
}

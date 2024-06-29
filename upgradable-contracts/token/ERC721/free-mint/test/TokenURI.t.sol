// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FreeMint} from "src/FreeMint.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "@openzeppelin-contracts-4.9.6/utils/Strings.sol";

contract FreeMint_TokenURI is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_returning_token_uri_for_unminted_token()
        external
    {
        vm.startPrank({msgSender: user1});
        vm.expectRevert("ERC721: invalid token ID");
        freemintContract.tokenURI(1);
    }

    function test_should_return_correct_tokenURI_for_minted_token() external {
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        vm.startPrank({msgSender: user1});
        string memory expectedMetadataFirstToken = expectedMetadata(1);
        freemintContract.mint();
        string memory metadataFirstToken = freemintContract.tokenURI(1);

        vm.startPrank({msgSender: user2});
        string memory expectedMetadataSecondToken = expectedMetadata(2);
        freemintContract.mint();
        string memory metadataSecondToken = freemintContract.tokenURI(2);

        assertEq(
            keccak256(abi.encodePacked((expectedMetadataFirstToken))),
            keccak256(abi.encodePacked(metadataFirstToken))
        );

        assertEq(
            keccak256(abi.encodePacked(expectedMetadataSecondToken)),
            keccak256(abi.encodePacked(metadataSecondToken))
        );
    }
}

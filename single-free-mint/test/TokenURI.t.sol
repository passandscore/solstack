// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {SingleFreeMint} from "src/SingleFreeMint.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract TokenURI is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function testShouldRevertWhenReturningTokenUriForUnmintedToken()
        external
    {
        vm.startPrank({msgSender: _user1});
        vm.expectRevert("ERC721: invalid token ID");
        _freemintContract.tokenURI(1);
    }

    function testShouldReturnCorrectTokenURIForMintedToken() external {
        vm.startPrank({msgSender: _user1});
        string memory expectedMetadataFirstToken = _expectedMetadata(1);
        _freemintContract.mint();
        string memory metadataFirstToken = _freemintContract.tokenURI(1);

        vm.startPrank({msgSender: _user2});
        string memory expectedMetadataSecondToken = _expectedMetadata(2);
        _freemintContract.mint();
        string memory metadataSecondToken = _freemintContract.tokenURI(2);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {SingleFreeMint} from "src/SingleFreeMint.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract Mint is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
        vm.startPrank({msgSender: _deployer});
    }

    function testShouldReturnZeroMintedWhenNoneMinted() external {
        assertEq(_freemintContract.totalSupply(), 0);
    }

    function testShouldReturnProperMintedCount() external {
        _freemintContract.mint();

        vm.startPrank({msgSender: _user1});
        _freemintContract.mint();

        vm.startPrank({msgSender: _user2});
        _freemintContract.mint();

        assertEq(_freemintContract.totalSupply(), 3);
    }

    function testShouldRevertWhenAlreadyMinted() external {
        _freemintContract.mint();
        vm.expectRevert(SingleFreeMint.TokenAlreadyMinted.selector);
        _freemintContract.mint();
    }
}

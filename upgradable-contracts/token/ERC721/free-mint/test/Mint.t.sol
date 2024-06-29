// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FreeMint} from "src/FreeMint.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "@openzeppelin-contracts-4.9.6/utils/Strings.sol";

contract FreeMint_Mint is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
        vm.startPrank({msgSender: deployer});
    }

    function test_should_revert_when_mint_paused_and_no_duration_set()
        external
    {
        freemintContract.pauseMint();
        vm.expectRevert(FreeMint.MintingNotEnabled.selector);
        freemintContract.mint();
    }

    function test_should_revert_when_duration_set_but_minting_paused()
        external
    {
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        freemintContract.pauseMint();

        vm.expectRevert(FreeMint.MintingNotEnabled.selector);
        freemintContract.mint();
    }

    function test_should_return_zero_minted_when_none_minted() external {
        assertEq(freemintContract.totalSupply(), 0);
    }

    function test_should_return_proper_minted_count_when_mint_unpaused()
        external
    {
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        freemintContract.mint();

        vm.startPrank({msgSender: user1});
        freemintContract.mint();

        vm.startPrank({msgSender: user2});
        freemintContract.mint();

        assertEq(freemintContract.totalSupply(), 3);
    }

    function test_should_revert_when_already_minted() external {
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        freemintContract.mint();
        vm.expectRevert(FreeMint.TokenAlreadyMinted.selector);
        freemintContract.mint();
    }

    function test_should_mint_when_unpaused_and_then_revert_when_paused()
        external
    {
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        freemintContract.mint();

        freemintContract.pauseMint();
        vm.expectRevert(FreeMint.MintingNotEnabled.selector);

        vm.startPrank({msgSender: user1});
        freemintContract.mint();
    }

    function test_should_prevent_minting_when_minting_duration_has_ended()
        external
    {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;

        setMintingWindow(startTime, endTime);

        freemintContract.mint();

        vm.startPrank({msgSender: user1});
        freemintContract.mint();

        vm.startPrank({msgSender: user2});
        freemintContract.mint();

        vm.warp(endTime + 1);

        vm.expectRevert(FreeMint.MintingNotEnabled.selector);
        freemintContract.mint();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FreeMint} from "src/FreeMint.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "openzeppelin-contracts/utils/Strings.sol";

contract FreeMint_Pause is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_setting_mint_paused_as_unauthorized_user()
        external
    {
        vm.startPrank({msgSender: unauthorizedUser});
        vm.expectRevert("Ownable: caller is not the owner");
        freemintContract.pauseMint();
    }

    function test_should_revert_when_resuming_mint_as_unauthorized_user()
        external
    {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;
        setMintingWindow(startTime, endTime);

        vm.startPrank({msgSender: user1});
        freemintContract.mint();

        vm.startPrank({msgSender: deployer});
        freemintContract.pauseMint();

            vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank({msgSender: unauthorizedUser});
        freemintContract.resumeMint();
    }

    function test_should_pause_mint() external {
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

    function test_should_resume_mint() external {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;

        setMintingWindow(startTime, endTime);

        freemintContract.mint();

         vm.startPrank({msgSender: deployer});
        freemintContract.pauseMint();

        vm.expectRevert(FreeMint.MintingNotEnabled.selector);
        vm.startPrank({msgSender: user1});
        freemintContract.mint();

        vm.startPrank({msgSender: deployer});
        freemintContract.resumeMint();

        vm.startPrank({msgSender: user2});
        freemintContract.mint();

        assertEq(freemintContract.totalSupply(), 2);
    }
}

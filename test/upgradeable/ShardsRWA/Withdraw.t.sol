// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import {CustomErrors} from "src/upgradeable/ShardsRWA/CustomErrors.sol";

contract ERC721LACore_WithdrawAmount is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();

        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        uint256 price = calculateTotalPrice(5);
        shardsRWA.mintSingleShards{value: price}(deployer, 5, false);
        vm.stopPrank();
    }
    // When primary royality of 100% is set, there is never a case where funds will be left in the contract.

    // function test_contract_contains_correct_balance() public view {
    //     uint256 balance = shardsRWA.balance();
    //     assertEq(balance, calculateTotalPrice(5));
    // }

    // function test_should_return_correct_amount() public {
    //     vm.startPrank(deployer);
    //     shardsRWA.withdrawAmount(
    //         payable(address(user1)),
    //         calculateTotalPrice(1)
    //     );

    //     uint256 balance = shardsRWA.balance();
    //     assertEq(balance, calculateTotalPrice(4));
    // }

    function test_should_revert_with_FundTransferError_when_trying_to_withdraw_an_amount()
        public
    {
        vm.startPrank(deployer);
        uint256 amount = calculateTotalPrice(1);
        vm.expectRevert(CustomErrors.FundTransferError.selector);
        shardsRWA.withdrawAmount(payable(address(failedReceiver)), amount);
    }

    function test_should_revert_with_FundTransferError_when_trying_to_withdraw_all_funds()
        public
    {
        vm.startPrank(deployer);
        vm.expectRevert(CustomErrors.FundTransferError.selector);
        shardsRWA.withdrawAll(payable(address(failedReceiver)));
    }
}

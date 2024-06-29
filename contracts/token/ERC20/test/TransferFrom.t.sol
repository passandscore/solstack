// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract ERC20_TransferFrom is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_amount_exceeds_balance()
        external
    {
        // transfer: deployer -> user1
        vm.startPrank({msgSender: deployer});
        contractUnderTest.transfer(user1, 500);
        vm.stopPrank();

        vm.startPrank({msgSender: user1});
        vm.expectRevert("ERC20: transfer amount exceeds balance");

        // transfer: user1 -> user2
        contractUnderTest.transfer(user2, 501);
    }

    function test_should_revert_when_amount_exceed_allowance() external {
        // approve: user1 -> user2
        vm.startPrank({msgSender: user1});
        contractUnderTest.approve(user2, 500);
        vm.stopPrank();

        // transferFrom: (user2) user1 -> user2
        vm.startPrank({msgSender: user2});
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        contractUnderTest.transferFrom(user1, user2, 501);
    }

    function test_should_revert_transfer_when_from_is_zero_address() external {
        // transfer: address(0) -> user1
        vm.startPrank({msgSender: address(0)});
        vm.expectRevert("ERC20: transfer from the zero address");
        contractUnderTest.transfer(user1, 1000);
    }

    function test_should_revert_transfer_when_to_is_zero_address() external {
        // transfer: deployer -> address(0)
        vm.startPrank({msgSender: deployer});
        vm.expectRevert("ERC20: transfer to the zero address");
        contractUnderTest.transfer(address(0), 1000);
    }

    function test_should_perform_transferFrom() external {
        // transfer: deployer -> user1
        vm.startPrank({msgSender: deployer});
        contractUnderTest.transfer(user1, 1000);
        vm.stopPrank();

        // approve: user1 -> user2
        vm.startPrank({msgSender: user1});
        contractUnderTest.approve(user2, 500);
        vm.stopPrank();

        // transferFrom: (user2) user1 -> user2
        vm.startPrank({msgSender: user2});
        contractUnderTest.transferFrom(user1, user2, 500);
    }

    function test_should_emit_transfer_event() external {
        // transfer: deployer -> user1
        vm.startPrank({msgSender: deployer});
        contractUnderTest.transfer(user1, 1000);

        // approve: user1 -> user2
        vm.startPrank({msgSender: user1});
        contractUnderTest.approve(user2, 500);
        vm.stopPrank();

        // transferFrom: (user2) user1 -> user2
        vm.startPrank({msgSender: user2});
        vm.expectEmit();
        emit IERC20.Transfer(user1, user2, 500);

        contractUnderTest.transferFrom(user1, user2, 500);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract ERC20_Approve is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_owner_is_zero_address() external {
        vm.startPrank({msgSender: address(0)});
        vm.expectRevert("ERC20: approve from the zero address");
        contractUnderTest.approve(user1, 1000);
    }

    function test_should_revert_when_spender_is_zero_address() external {
        vm.startPrank({msgSender: deployer});
        vm.expectRevert("ERC20: approve to the zero address");
        contractUnderTest.approve(address(0), 1000);
    }

    function test_should_set_proper_allowance() external {
        vm.startPrank({msgSender: deployer});
        contractUnderTest.approve(user1, 1000);

        uint256 allowance = contractUnderTest.allowance(deployer, user1);
        assertEq(allowance, 1000);
    }

    function test_should_emit_approval_event() external {
        vm.startPrank({msgSender: deployer});

        vm.expectEmit();
        emit IERC20.Approval(deployer, user1, 1000);

        contractUnderTest.approve(user1, 1000);
    }

    function test_should_return_true_when_approve_is_successful() external {
        vm.startPrank({msgSender: deployer});
        bool result = contractUnderTest.approve(user1, 1000);
        assertTrue(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract ERC20_Burn is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_receiver_is_zero_address() external {
        vm.startPrank({msgSender: address(0)});
        vm.expectRevert("ERC20: burn from the zero address");
        contractUnderTest.burn(address(0), 1000);
    }

    function test_should_revert_if_burn_causes_underflow() external {
        uint256 maxSupply = type(uint256).max;

        // revert -> panic: arithmetic underflow
        vm.startPrank({msgSender: deployer});
        vm.expectRevert();
        contractUnderTest.burn(user1, maxSupply + 1);
    }

    function test_should_revert_if_amount_exceeds_balance() external {
        vm.startPrank({msgSender: deployer});
        vm.expectRevert("ERC20: burn amount exceeds balance");
        contractUnderTest.burn(deployer, TOTAL_SUPPLY + 1);
    }

    function test_should_update_user_balance() external {
        vm.startPrank({msgSender: deployer});
        contractUnderTest.burn(deployer, 1);

        uint256 balance = contractUnderTest.balanceOf(deployer);
        assertEq(balance, TOTAL_SUPPLY - 1);
    }

    function test_should_emit_transfer_event() external {
        vm.startPrank({msgSender: deployer});

        vm.expectEmit();
        emit IERC20.Transfer(deployer, address(0), 1000);

        contractUnderTest.burn(deployer, 1000);
    }
}

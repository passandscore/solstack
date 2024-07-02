// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract ERC20_Mint is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_receiver_is_zero_address() external {
        vm.startPrank({msgSender: deployer});
        vm.expectRevert("ERC20: mint to the zero address");
        contractUnderTest.mint(address(0), 1000);
    }

    function test_should_revert_if_mint_exceeds_total_supply() external {
        uint256 maxSupply = type(uint256).max;
        uint256 remainingSupply = maxSupply - TOTAL_SUPPLY;

        // revert -> panic: arithmetic overflow
        vm.startPrank({msgSender: deployer});
        vm.expectRevert();
        contractUnderTest.mint(user1, remainingSupply + 1);
    }

    function test_should_update_user_balance() external {
        vm.startPrank({msgSender: deployer});
        contractUnderTest.mint(user1, 1000);

        uint256 balance = contractUnderTest.balanceOf(user1);
        assertEq(balance, 1000);
    }

    function test_should_emit_transfer_event() external {
        vm.startPrank({msgSender: deployer});

        vm.expectEmit();
        emit IERC20.Transfer(address(0), user1, 1000);

        contractUnderTest.mint(user1, 1000);
    }
}

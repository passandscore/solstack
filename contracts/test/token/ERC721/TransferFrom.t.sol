// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {IERC721Errors} from "src/interfaces/IERC6093.sol";
import {IERC721} from "src/interfaces/IERC721.sol";

contract ERC721_TransferFrom is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_if_to_is_zero_address() public {
        address to = address(0);
        uint256 tokenId = 1;

        // mint token
        address owner = deployer;
        contractUnderTest.mint(owner, tokenId);

        bytes4 selector = IERC721Errors.ERC721InvalidReceiver.selector;

        vm.expectRevert(abi.encodeWithSelector(selector, to));
        contractUnderTest.transferFrom(owner, to, tokenId);
    }

    function test_should_revert_if_from_is_not_owner() public {
        vm.startPrank(deployer);

        // mint token
        address owner = deployer;
        uint256 tokenId = 1;
        contractUnderTest.mint(owner, tokenId);

        // approve user1 to transfer token
        contractUnderTest.approve(user1, tokenId);
        vm.stopPrank();

        bytes4 selector = IERC721Errors.ERC721IncorrectOwner.selector;

        vm.expectRevert(
            abi.encodeWithSelector(selector, user2, tokenId, owner)
        );

        // user2 tries to transfer token
        vm.startPrank(user1);
        contractUnderTest.transferFrom(user2, user1, tokenId);
    }

    function test_should_revert_whern_token_is_non_existent() public {
        vm.startPrank(deployer);

        address owner = deployer;
        uint256 tokenId = 1;
        uint256 nonExistentTokenId = 2;

        // mint token
        contractUnderTest.mint(owner, tokenId);

        // approve user1 to transfer token
        contractUnderTest.approve(user1, tokenId);
        vm.stopPrank();

        bytes4 selector = IERC721Errors.ERC721NonexistentToken.selector;

        vm.expectRevert(abi.encodeWithSelector(selector, nonExistentTokenId));

        // user1 tries to transfer token
        vm.startPrank(user1);
        contractUnderTest.transferFrom(owner, user1, nonExistentTokenId);
    }

    function test_should_revert_when_insufficent_approval() public {
        vm.startPrank(deployer);

        address owner = deployer;
        uint256 tokenId = 1;

        // mint token
        contractUnderTest.mint(owner, tokenId);

        // no approval to user1
        vm.stopPrank();

        bytes4 selector = IERC721Errors.ERC721InsufficientApproval.selector;

        vm.expectRevert(abi.encodeWithSelector(selector, user1, tokenId));

        // user1 tries to transfer token
        vm.startPrank(user1);
        contractUnderTest.transferFrom(owner, user1, tokenId);
    }

    function test_should_update_balance_when_transfer_is_successful() public {
        vm.startPrank(deployer);

        address owner = deployer;
        uint256 tokenId = 1;

        // mint token
        contractUnderTest.mint(owner, tokenId);

        // approve user1 to transfer token
        contractUnderTest.approve(user1, tokenId);
        vm.stopPrank();

        // user1 transfers token
        vm.startPrank(user1);
        contractUnderTest.transferFrom(owner, user1, tokenId);

        assertEq(contractUnderTest.balanceOf(owner), 0);
        assertEq(contractUnderTest.balanceOf(user1), 1);
    }

    function test_should_emit_transfer_event_when_transfer_is_successful()
        public
    {
        vm.startPrank(deployer);

        address owner = deployer;
        uint256 tokenId = 1;

        // mint token
        contractUnderTest.mint(owner, tokenId);

        // approve user1 to transfer token
        contractUnderTest.approve(user1, tokenId);
        vm.stopPrank();

        // user1 transfers token
        vm.startPrank(user1);

        vm.expectEmit();
        emit IERC721.Transfer(owner, user1, tokenId);

        contractUnderTest.transferFrom(owner, user1, tokenId);
        
    }
}

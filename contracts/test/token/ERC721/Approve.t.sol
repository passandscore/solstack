// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {IERC721Errors} from "src/interfaces/IERC6093.sol";
import {IERC721} from "src/interfaces/IERC721.sol";


contract ERC721_Approve is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_approve_user() public {
        address owner = deployer;
        address to = user1;
        uint256 tokenId = 1;

        // mint token
        vm.startPrank(owner);
        contractUnderTest.mint(owner, tokenId);


        contractUnderTest.approve(to, 1);
        assertEq(contractUnderTest.getApproved(1), to);
    }

    function test_should_approve_user_for_all_tokens() public {
        address owner = deployer;
        address to = user1;
        

        // mint token
        vm.startPrank(owner);
        contractUnderTest.mint(owner, 1);
        contractUnderTest.mint(owner, 2);
        contractUnderTest.mint(owner, 3);

        contractUnderTest.setApprovalForAll(to, true);

        assert(contractUnderTest.isApprovedForAll(owner, to));
    }

    function test_should_emit_approval_event_when_approving() public {

        address owner = deployer;
        address to = user1;
        uint256 tokenId = 1;

        // mint token
        vm.startPrank(owner);
        contractUnderTest.mint(owner, tokenId);


         vm.expectEmit();
        emit IERC721.Approval(owner, to, tokenId);

        contractUnderTest.approve(to, 1);

    }
}

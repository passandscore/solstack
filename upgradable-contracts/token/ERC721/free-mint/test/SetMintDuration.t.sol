// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FreeMint} from "src/FreeMint.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "@openzeppelin-contracts-4.9.6/utils/Strings.sol";

contract FreeMint_SetMintDuration is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_setting_mint_duration_as_unauthorized_user()
        external
    {
        vm.startPrank({msgSender: unauthorizedUser});
        vm.expectRevert("Ownable: caller is not the owner");
        freemintContract.setMintDuration(uint32(block.timestamp), uint32(block.timestamp + 100));
    }

    function test_should_set_mint_duration() external {
        uint32 startTime = uint32(block.timestamp);
        uint32 endTime = uint32(block.timestamp + 100);

        vm.startPrank({msgSender: deployer});
        freemintContract.setMintDuration(startTime, endTime);

        assertEq(freemintContract._mintStartTime(), startTime);


    }

   
}

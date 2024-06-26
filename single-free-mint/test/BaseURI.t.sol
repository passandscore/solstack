// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {SingleFreeMint} from "src/SingleFreeMint.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract BaseURI is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function testShouldRevertWhenSettingBaseUriAsUnauthorizedUser()
        external
    {
        vm.startPrank({msgSender: _unauthorizedUser});
        vm.expectRevert("Ownable: caller is not the owner");
        _freemintContract.setBaseURI("test.com");
    }

    function testShouldSetBaseUri() external {
        vm.startPrank({msgSender: _deployer});
        _freemintContract.setBaseURI("newURI.com");
        assertEq(_freemintContract.assetBaseURI(), "newURI.com");
    }

   
}

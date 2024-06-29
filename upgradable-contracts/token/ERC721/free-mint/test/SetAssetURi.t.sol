// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FreeMint} from "src/FreeMint.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "openzeppelin-contracts/utils/Strings.sol";

contract FreeMint_SetAssetURI is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_setting_base_uri_as_unauthorized_user()
        external
    {
        vm.startPrank({msgSender: unauthorizedUser});
        vm.expectRevert("Ownable: caller is not the owner");
        freemintContract.setAssetURI("test.com");
    }

    function test_should_set_base_uri() external {
        string memory newAssetURI = "newURI.com";
        assertNotEq(freemintContract._assetURI(), newAssetURI);

        vm.startPrank({msgSender: deployer});
        freemintContract.setAssetURI(newAssetURI);
        assertEq(freemintContract._assetURI(), newAssetURI);
    }

   
}

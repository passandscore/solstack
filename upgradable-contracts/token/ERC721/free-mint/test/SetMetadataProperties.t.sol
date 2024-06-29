// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FreeMint} from "src/FreeMint.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "@openzeppelin-contracts-4.9.6/utils/Strings.sol";

contract FreeMint_SetMetadataProperties is ContractUnderTest {
    string _newNftName = "newNftName";
    string _newArtistName = "newArtistName";
    string _newDescription = "newDescription";

    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_setting_metadata_as_unauthorized_user()
        external
    {
        vm.startPrank({msgSender: unauthorizedUser});
        vm.expectRevert("Ownable: caller is not the owner");
        freemintContract.setMetadataProperties(
            _newNftName,
            _newArtistName,
            _newDescription
        );
    }

    function test_should_set_new_metadata_properties() external {

        string memory currentNftName = freemintContract._nftName();
        string memory currentArtistName = freemintContract._artistName();
        string memory currentDescription = freemintContract._description();


        vm.startPrank({msgSender: deployer});
        freemintContract.setMetadataProperties(_newNftName, _newArtistName, _newDescription);

        assertNotEq(currentNftName, _newNftName);
        assertNotEq(currentArtistName, _newArtistName);
        assertNotEq(currentDescription, _newDescription);

        assertEq(freemintContract._nftName(), _newNftName);
        assertEq(freemintContract._artistName(), _newArtistName);
        assertEq(freemintContract._description(), _newDescription);
    }
}

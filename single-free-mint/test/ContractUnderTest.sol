// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {SingleFreeMint} from "src/SingleFreeMint.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "forge-std/Test.sol";

abstract contract ContractUnderTest is Test {
    SingleFreeMint internal _freemintContract;

    address payable _deployer = payable(makeAddr("deployer"));
    address payable _user1 = payable(makeAddr("user1"));
    address payable _user2 = payable(makeAddr("user2"));
    address payable _unauthorizedUser = payable(makeAddr("unauthorizedUser"));

    function setUp() public virtual {
        _freemintContract = new SingleFreeMint();

        vm.startPrank({msgSender: _deployer});

        vm.label({
            account: address(_freemintContract),
            newLabel: "SingleFreeMint"
        });

        _freemintContract.initialize("SingleFreeMint", "SM", "test.com");
    }

    function _expectedMetadata(
        uint256 tokenId
    ) internal pure returns (string memory) {
        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "FreeMint #',
                        Strings.toString(tokenId),
                        '",',
                        '{ "tokenId": ',
                        Strings.toString(tokenId),
                        '",',
                        '"image": "https://v2-liveart.mypinata.cloud/ipfs/QmegWT8hUctpxx4RV643ZWDBo2FjtzFJ8mVhpUFAeWnSca",',
                        '"properties": { "artistName": "Unknown" },',
                        '"description": "This is a free mint",',
                        "}"
                    )
                )
            )
        );

        return metadata;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Fork} from "./utils/Fork.sol";
import {FreeMint} from "src/FreeMint.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "openzeppelin-contracts/utils/Base64.sol";

abstract contract ContractUnderTest is Fork {
    FreeMint internal freemintContract;

    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));
    address payable unauthorizedUser = payable(makeAddr("unauthorizedUser"));

    function setUp() public virtual override {
        vm.selectFork(mainnetFork);
        super.setUp();

        freemintContract = new FreeMint();

        vm.startPrank({msgSender: deployer});

        vm.label({account: address(freemintContract), newLabel: "FreeMint"});

        freemintContract.initialize("FreeMint", "FM", "test.com");
        freemintContract.setMetadataProperties(
            "nft name goes here",
            "artist name goes here",
            "description goes here"
        );
    }

    function expectedMetadata(
        uint256 tokenId
    ) internal view returns (string memory) {
        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "',
                        freemintContract._nftName(),
                        " #",
                        Strings.toString(tokenId),
                        '", "tokenId": "',
                        Strings.toString(tokenId),
                        '", "image": "',
                        freemintContract._assetURI(),
                        '", "properties": { "artistName": "',
                        freemintContract._artistName(),
                        '"}, "description": "',
                        freemintContract._description(),
                        '"}'
                    )
                )
            )
        );

        return metadata;
    }

    function setMintingWindow(uint256 startTime, uint256 endTime) internal {
        freemintContract.setMintDuration(uint32(startTime), uint32(endTime));
    }
}

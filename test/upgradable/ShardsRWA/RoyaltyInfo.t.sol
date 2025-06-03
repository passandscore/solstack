// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";

contract ERC721Core_RoyaltyInfo is ContractUnderTest {
    string newNftName = "fractional.art";

    function setUp() public virtual override {
        ContractUnderTest.setUp();
    }
    
     function test_should_return_proper_info_when_royalty_receiver() external {
        vm.startPrank(royaltyReceiver);

        uint256 tokenId = 1;
        uint256 salePrice = 1000;
        uint256 MAX_BPS = 10000;

        (address receiver, uint256 royaltyAmount) = shardsRWA.royaltyInfo(
            tokenId,
            salePrice
        );

        vm.assertEq(receiver, royaltyReceiver);
        vm.assertEq(
            royaltyAmount,
            (salePrice * shardsRWA.secondarySalePercentage()) / MAX_BPS
        );
    }
}

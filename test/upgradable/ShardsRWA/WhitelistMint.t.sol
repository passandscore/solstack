// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ContractUnderTest} from "./ContractUnderTest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {CustomErrors} from "src/upgradable/ShardsRWA/CustomErrors.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Merkle} from "@murky-0.1.0/src/Merkle.sol";
import "forge-std/console.sol";

contract ERC721_WhitelistMint is ContractUnderTest {
    address payable wlUser1 = payable(makeAddr("wlUser1"));
    address payable wlUser2 = payable(makeAddr("wlUser2"));

    uint256 totalPrice;
    address[] whitelistedUsers;
    bytes32 whitelistMerkleRoot;
    uint256 whitelistMintStartTime;
    uint256 whitelistMintEndTime;
    uint256 whitelistMintPrice;
    bool whitelistEnabled;

    function setUp() public virtual override {
        ContractUnderTest.setUp();
        uint256 shardsPerPack = 100;
        
        // Set whitelist prices
        uint16[] memory quantities = new uint16[](6);
        quantities[0] = 1;
        quantities[1] = 5;
        quantities[2] = 10;
        quantities[3] = 25;
        quantities[4] = 50;
        quantities[5] = 100;
        
        uint256[] memory prices = new uint256[](6);
        prices[0] = 0.00614 ether;
        prices[1] = 0.00246 ether;
        prices[2] = 0.00246 ether;
        prices[3] = 0.00246 ether;
        prices[4] = 0.00225 ether;
        prices[5] = 0.00225 ether;
        
        vm.startPrank(deployer);
        shardsRWA.batchSetShardPrices(quantities, prices, true);
        vm.stopPrank();
        
        totalPrice = shardsRWA.getShardPricePerPack(100, true) * shardsPerPack;

        vm.deal(wlUser1, 100 ether);
        vm.deal(wlUser2, 100 ether);

        vm.label(wlUser1, "wlUser1");
        vm.label(wlUser2, "wlUser2");

        whitelistedUsers = [wlUser1, wlUser2];

        // Set up minting window and whitelist
        vm.startPrank(deployer);
        
        // Set mint window to start in 24 hours and last for 2 days
        uint256 mintStart = block.timestamp + 24 hours;
        uint256 mintEnd = mintStart + 2 days;
        setMintingWindow(mintStart, mintEnd);
        
        // Enable whitelist with 24 hour window before mint starts
        shardsRWA.setWhitelistMintConfig(true, 24); // 24 hours before mint starts
        
        // Generate and set merkle root
        Merkle merkle = new Merkle();
        bytes32[] memory data = new bytes32[](whitelistedUsers.length);
        for (uint256 i = 0; i < whitelistedUsers.length; i++) {
            data[i] = keccak256(abi.encodePacked(whitelistedUsers[i]));
        }
        whitelistMerkleRoot = merkle.getRoot(data);
        shardsRWA.setMerkleRoot(whitelistMerkleRoot);
        vm.stopPrank();
    }

    function generateMerkleProof(
        uint256 node
    ) public returns (bytes32[] memory WLProof) {
        Merkle merkle = new Merkle();

        bytes32[] memory data = new bytes32[](whitelistedUsers.length);
        for (uint256 i = 0; i < whitelistedUsers.length; i++) {
            data[i] = keccak256(abi.encodePacked(whitelistedUsers[i]));
        }

        vm.startPrank(deployer);
        bytes32 root = merkle.getRoot(data);
        shardsRWA.setMerkleRoot(root);
        vm.stopPrank();

        return merkle.getProof(data, node);
    }

    function test_should_mint_when_whitelist_is_enabled() public {
        // Warp to whitelist period (12 hours before mint starts)
        vm.warp(block.timestamp + 12 hours);
        
        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        uint256 mintPrice = shardsRWA.getShardPricePerPack(1, true) * 1;

        vm.startPrank(wlUser1);
        shardsRWA.whitelistMint{value: mintPrice}(WLProof, wlUser1, 1, false, false);
        vm.stopPrank();
    }

    function test_should_mint_when_whitelist_is_enabled_and_max_pack() public {
        // Warp to whitelist period
        vm.warp(block.timestamp + 1 hours);

        uint256 node = 1;
        bytes32[] memory WLProof = generateMerkleProof(node);

        uint256 mintPrice = shardsRWA.getShardPricePerPack(100, true) * 100; // Price for max pack (100 shards)

        vm.startPrank(wlUser2);
        shardsRWA.whitelistMint{value: mintPrice}(WLProof, wlUser2, 1, true, false);
        vm.stopPrank();
    }

    function test_should_revert_when_whitelist_is_disabled() public {
        bool isWhitelistEnabled = false;
        vm.startPrank(deployer);
        // First clear merkle root to ensure whitelist check happens first
        shardsRWA.setMerkleRoot(bytes32(0));
        // Then disable whitelist
        shardsRWA.setWhitelistMintConfig(isWhitelistEnabled, whitelistMintEndTime - whitelistMintStartTime);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        // Create empty proof since we don't need a valid one
        bytes32[] memory WLProof = new bytes32[](0);

        uint256 mintPrice = shardsRWA.getShardPricePerPack(1, true) * 1;

        vm.startPrank(wlUser1);
        vm.expectRevert(CustomErrors.WhitelistNotEnabled.selector);
        shardsRWA.whitelistMint{value: mintPrice}(WLProof, wlUser1, 1, false, false);
        vm.stopPrank();
    }

    function test_should_revert_when_not_whitelisted() public {
        // Warp to whitelist period (12 hours before mint starts)
        vm.warp(block.timestamp + 12 hours);

        address nonWhitelisted = unauthorizedUser;
        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        uint256 mintPrice = shardsRWA.getShardPricePerPack(1, true) * 1;

        vm.startPrank(nonWhitelisted);
        vm.expectRevert(CustomErrors.NotWhitelisted.selector);
        shardsRWA.whitelistMint{value: mintPrice}(WLProof, nonWhitelisted, 1, false, false);
        vm.stopPrank();
    }

    function test_should_revert_when_mint_time_is_not_started() public {
        // In setUp, mint starts at block.timestamp + 24 hours
        // Whitelist period is 24 hours before mint start
        // So whitelist period is from block.timestamp to block.timestamp + 24 hours
        // Let's warp to before whitelist period
        vm.warp(block.timestamp - 1 hours);

        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        uint256 mintPrice = shardsRWA.getShardPricePerPack(1, true) * 1;

        vm.startPrank(wlUser1);
        vm.expectRevert(CustomErrors.WhitelistNotEnabled.selector);
        shardsRWA.whitelistMint{value: mintPrice}(WLProof, wlUser1, 1, false, false);
        vm.stopPrank();
    }

    function test_should_revert_when_mint_time_is_over() public {
        // Warp to after whitelist period ends (at mint start time)
        vm.warp(block.timestamp + 24 hours + 1 minutes); // Just past the whitelist window

        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        uint256 mintPrice = shardsRWA.getShardPricePerPack(1, true) * 1;

        vm.startPrank(wlUser1);
        vm.expectRevert(CustomErrors.WhitelistNotEnabled.selector);
        shardsRWA.whitelistMint{value: mintPrice}(WLProof, wlUser1, 1, false, false);
        vm.stopPrank();
    }

    function test_should_properly_mint_different_pack_sizes_with_token() public {
        uint16[] memory packSizes = new uint16[](5);
        packSizes[0] = 1;
        packSizes[1] = 5;
        packSizes[2] = 10;
        packSizes[3] = 25;
        packSizes[4] = 50;

        vm.warp(block.timestamp + 12 hours);

        vm.startPrank(wlUser1);
        mockERC20Token.mint(wlUser1, 1000 ether);
        mockERC20Token.approve(address(shardsRWA), 1000 ether);
        vm.stopPrank();
        
        uint256 totalMinted = 0;
        uint256 totalPaid = 0;

        for (uint256 i = 0; i < packSizes.length; i++) {
            uint16 packSize = packSizes[i];
            uint256 pricePerShard = shardsRWA.getShardPricePerPack(packSize, true);
            uint256 t_price = pricePerShard * packSize;
            uint256 initialBalance = mockERC20Token.balanceOf(wlUser1);
            uint256 initialSupply = shardsRWA.totalSupply();

            uint256 node = 0;
            bytes32[] memory WLProof = generateMerkleProof(node);

            vm.startPrank(wlUser1);
            shardsRWA.whitelistMint(WLProof, wlUser1, packSize, false, true);
            vm.stopPrank();

            totalMinted += packSize;
            totalPaid += t_price;

            assertEq(shardsRWA.totalSupply(), initialSupply + packSize);
            assertEq(mockERC20Token.balanceOf(wlUser1), initialBalance - t_price);
            assertEq(mockERC20Token.balanceOf(royaltyReceiver), totalPaid);
        }

        assertEq(shardsRWA.totalSupply(), totalMinted);
        assertEq(mockERC20Token.balanceOf(wlUser1), 1000 ether - totalPaid);
        assertEq(mockERC20Token.balanceOf(royaltyReceiver), totalPaid);
    }
}

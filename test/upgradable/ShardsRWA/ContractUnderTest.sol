// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FailedCallReceiver} from "test/mocks/FailedCallReceiver.sol";
import {ShardsRWA} from "src/upgradable/ShardsRWA/ShardsRWA.sol";
import {MockERC20Token} from "test/mocks/ERC20Mock.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/Test.sol";

// ex: forge clean && source .env && forge test  --via-ir -vvvv

abstract contract ContractUnderTest is Test {
    ShardsRWA internal shardsRWA;
    FailedCallReceiver internal failedCallReceiver;
    MockERC20Token internal mockERC20Token;

    uint256 public mainnetFork;

    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));
    address payable user3 = payable(makeAddr("user3"));
    address payable unauthorizedUser = payable(makeAddr("unauthorizedUser"));
    address payable failedReceiver;
    address payable royaltyReceiver =
        payable(makeAddr("royaltyReceiver"));
    uint48 primarySalePercentage = 10000;
    uint48 secondarySalePercentage = 500;

    function setUp() public virtual {
        string memory mainnet_rpc_url_key = "RPC_URL";
        string memory mainnet_rpc_url = vm.envString(mainnet_rpc_url_key);
        mainnetFork = vm.createFork(mainnet_rpc_url);
        
        vm.selectFork(mainnetFork);

        shardsRWA = new ShardsRWA(); // Base Mainnet fork
        mockERC20Token = new MockERC20Token();

        failedCallReceiver = new FailedCallReceiver();

        failedReceiver = payable(address(failedCallReceiver));

        vm.startPrank({msgSender: deployer});
        vm.warp(block.timestamp);

        vm.label({account: address(shardsRWA), newLabel: "ShardsRWA"});

        vm.deal(deployer, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(unauthorizedUser, 100 ether);

        string memory name = "ShardsRWA";
        string memory symbol = "ERC721";
        string memory baseURI = "https://api.example.com/v1/";
        uint256 maxSupply = 50000; // Increased to accommodate max pack minting

        shardsRWA.initialize(
            name,
            symbol,
            baseURI,
            maxSupply,
            primarySalePercentage,
            secondarySalePercentage,
            royaltyReceiver,
            address(mockERC20Token)
        );

        setDefaultPricesAndMultipliers();
    }

    function calculateTotalPrice(uint16 packSize) internal view returns (uint256) {
        return shardsRWA.getShardPricePerPack(packSize, _isWhitelistMint()) * packSize;
    }

    function _isWhitelistMint() internal view returns (bool) {
        (bool enabled, uint256 duration) = shardsRWA.getWhitelistDetails();
        (uint32 mintStart,) = shardsRWA.getMintingDuration();
        return enabled && block.timestamp >= mintStart - duration && block.timestamp < mintStart;
    }

    function setMintingWindow(uint256 startTime, uint256 endTime) internal {
        shardsRWA.setMintDuration(uint32(startTime), uint32(endTime));
    }

    function setDefaultPricesAndMultipliers() internal {
        vm.startPrank(deployer);
        
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
        
        string[] memory multipliers = new string[](6);
        multipliers[0] = "1.1";
        multipliers[1] = "1.2";
        multipliers[2] = "1.3";
        multipliers[3] = "1.4";
        multipliers[4] = "1.5";
        multipliers[5] = "1";
        
        shardsRWA.batchSetShardPrices(quantities, prices, false);
        shardsRWA.batchSetMultipliers(quantities, multipliers);
        
        vm.stopPrank();
    }
}
